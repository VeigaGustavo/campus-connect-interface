/// Contexto do perfil na API v2 (`GET/PUT /api/profile`): pessoa vs instituição.
enum ProfileContext {
  user,
  organization;

  /// Aceita `profile_context` da API; se ausente, infere por `profile_type` legado.
  static ProfileContext fromApi(
    dynamic raw, {
    AccountProfileType? legacyProfileType,
  }) {
    if (raw is String) {
      switch (raw.toLowerCase().trim()) {
        case 'organization':
          return ProfileContext.organization;
        case 'user':
          return ProfileContext.user;
      }
    }
    if (legacyProfileType != null &&
        legacyProfileType != AccountProfileType.estudante) {
      return ProfileContext.organization;
    }
    return ProfileContext.user;
  }
}

/// Papel da conta na UI (comunidade / empresa / universidade) — alinhado ao `role` do JWT
/// quando a API o espelha no JSON; senão usa `profile_type` legado.
enum AccountProfileType {
  estudante,
  comunidade,
  empresa,
  universidade;

  static AccountProfileType fromApiValue(dynamic raw) {
    final s = raw is String ? raw.toLowerCase().trim() : '';
    return switch (s) {
      'comunidade' => AccountProfileType.comunidade,
      'empresa' => AccountProfileType.empresa,
      'universidade' => AccountProfileType.universidade,
      _ => AccountProfileType.estudante,
    };
  }

  /// Monta o tipo de UI a partir do contrato v2 (`profile_context` + `role` / `profile_type`).
  static AccountProfileType fromProfilePayload({
    required ProfileContext profileContext,
    dynamic role,
    dynamic profileType,
  }) {
    if (profileContext == ProfileContext.user) {
      return AccountProfileType.estudante;
    }
    final r = _roleNorm(role) ?? _roleNorm(profileType);
    return switch (r) {
      'comunidade' => AccountProfileType.comunidade,
      'empresa' => AccountProfileType.empresa,
      'universidade' => AccountProfileType.universidade,
      _ => AccountProfileType.empresa,
    };
  }

  static String? _roleNorm(dynamic v) {
    if (v is! String) return null;
    final s = v.toLowerCase().trim();
    return s.isEmpty ? null : s;
  }

  bool get isInstitution => this != AccountProfileType.estudante;

  String get shellBarTitle => switch (this) {
        AccountProfileType.estudante => 'Perfil',
        AccountProfileType.comunidade => 'Comunidade',
        AccountProfileType.empresa => 'Empresa',
        AccountProfileType.universidade => 'Universidade',
      };

  String get verifiedBadgeLabel => isInstitution
      ? 'Instituição verificada'
      : 'Perfil verificado';

  String get kindChipLabel => switch (this) {
        AccountProfileType.estudante => 'Estudante',
        AccountProfileType.comunidade => 'Conta de comunidade',
        AccountProfileType.empresa => 'Conta de empresa',
        AccountProfileType.universidade => 'Conta de universidade',
      };

  String get settingsScreenTitle => isInstitution
      ? 'Configurações da instituição'
      : 'Configurações do perfil';

  String get settingsIntroLine => isInstitution
      ? 'Sobre a instituição, identidade pública e histórico visível só para administradores.'
      : 'Sobre o perfil, preferências e histórico visível só para você.';

  String get settingsEntrySubtitle => isInstitution
      ? 'Sobre a instituição, preferências e atividade.'
      : 'Sobre você, preferências e painel de atividade.';

  String get aboutCardTitle =>
      isInstitution ? 'Sobre a instituição' : 'Sobre mim';

  String get emptyAboutFallback => isInstitution
      ? 'Sem descrição institucional no momento.'
      : 'Sem descrição no momento.';

  String get preferencesSubtitle => isInstitution
      ? 'Temas, eixos de atuação e competências exibidos ao público.'
      : 'Gostos, topicos favoritos e especialidades do seu perfil.';

  String get activityPrivacyLine => isInstitution
      ? 'Histórico recente visível apenas para administradores da instituição.'
      : 'Histórico recente visível apenas para você.';
}

enum CommunityKind { athletic, academicCenter, community }

enum CommunityRole { member, director, president }

enum ProfileHistoryKind { post, reading, group }

class CommunityHighlight {
  const CommunityHighlight({
    required this.id,
    required this.name,
    required this.kind,
    required this.role,
  });

  final String id;
  final String name;
  final CommunityKind kind;
  final CommunityRole role;
}

class ProfileHistoryItem {
  const ProfileHistoryItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.referenceId,
    required this.createdAt,
  });

  final String id;
  final ProfileHistoryKind kind;
  final String title;
  final String subtitle;
  final String referenceId;
  final DateTime createdAt;
}

/// Item de listagem em `organization_panel` (vagas, eventos, grupos).
class OrganizationPanelListedItem {
  const OrganizationPanelListedItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.referenceId,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String referenceId;
  final DateTime createdAt;
}

/// Post resumido em `organization_panel.posts`.
class OrganizationPanelPost {
  const OrganizationPanelPost({
    required this.id,
    required this.preview,
    required this.createdAt,
  });

  final String id;
  final String preview;
  final DateTime createdAt;
}

/// Painel agregado para `profile_context: organization` (contrato v2).
class OrganizationPanel {
  const OrganizationPanel({
    this.parentInstitution,
    this.mapUrl,
    this.jobs = const [],
    this.events = const [],
    this.groups = const [],
    this.posts = const [],
    this.jobsTotal = 0,
    this.eventsTotal = 0,
    this.groupsTotal = 0,
    this.postsTotal = 0,
  });

  final String? parentInstitution;
  final String? mapUrl;
  final List<OrganizationPanelListedItem> jobs;
  final List<OrganizationPanelListedItem> events;
  final List<OrganizationPanelListedItem> groups;
  final List<OrganizationPanelPost> posts;
  final int jobsTotal;
  final int eventsTotal;
  final int groupsTotal;
  final int postsTotal;
}

class ProfileUpdateInput {
  const ProfileUpdateInput({
    required this.aboutMe,
    required this.jobTitle,
    required this.course,
    required this.semester,
    required this.institutionName,
    this.mapUrl = '',
    required this.interests,
    required this.favoriteTopics,
    required this.specialties,
  });

  final String aboutMe;
  final String jobTitle;
  final String course;
  final String semester;
  final String institutionName;
  /// Apenas universidade no `PUT /api/profile`; outros perfis ignoram.
  final String mapUrl;
  final List<String> interests;
  final List<String> favoriteTopics;
  final List<String> specialties;
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.profileContext,
    required this.profileType,
    required this.name,
    required this.coverImageUrl,
    required this.avatarImageUrl,
    required this.email,
    required this.cityState,
    required this.aboutMe,
    required this.jobTitle,
    required this.course,
    required this.semester,
    required this.institutionName,
    required this.applicationsCount,
    required this.groupsCount,
    required this.eventsCount,
    required this.interests,
    required this.favoriteTopics,
    required this.specialties,
    required this.communityHighlight,
    this.organizationPanel,
  });

  final String id;
  final ProfileContext profileContext;
  final AccountProfileType profileType;
  final String name;
  final String coverImageUrl;
  final String avatarImageUrl;
  final String email;
  final String cityState;
  final String aboutMe;
  final String jobTitle;
  final String course;
  final String semester;
  final String institutionName;
  final int applicationsCount;
  final int groupsCount;
  final int eventsCount;
  final List<String> interests;
  final List<String> favoriteTopics;
  final List<String> specialties;
  final CommunityHighlight? communityHighlight;

  /// Presente em modo organização; `null` em contas `user` ou API sem bloco.
  final OrganizationPanel? organizationPanel;

  /// Contrato v2: `profile_context == "organization"` — perfil da instituição.
  bool get isOrganizationProfile =>
      profileContext == ProfileContext.organization;

  UserProfile copyWith({
    String? avatarImageUrl,
    String? coverImageUrl,
  }) {
    return UserProfile(
      id: id,
      profileContext: profileContext,
      profileType: profileType,
      name: name,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      avatarImageUrl: avatarImageUrl ?? this.avatarImageUrl,
      email: email,
      cityState: cityState,
      aboutMe: aboutMe,
      jobTitle: jobTitle,
      course: course,
      semester: semester,
      institutionName: institutionName,
      applicationsCount: applicationsCount,
      groupsCount: groupsCount,
      eventsCount: eventsCount,
      interests: interests,
      favoriteTopics: favoriteTopics,
      specialties: specialties,
      communityHighlight: communityHighlight,
      organizationPanel: organizationPanel,
    );
  }
}
