import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/autenticacao/sessao_local.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/mensagem_erro_api.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/perfil/domain/perfil_usuario.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Future<_ProfileViewData>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _loadProfileView();
  }

  Future<void> _reload() async {
    final next = _loadProfileView();
    setState(() => _future = next);
    await next;
  }

  Future<_ProfileViewData> _loadProfileView() async {
    final repo = DependencyScope.of(context).profileRepository;
    final profile = await repo.getCurrentProfile();
    final history = await repo.getCurrentUserHistory(limit: 20);
    return _ProfileViewData(profile: profile, history: history);
  }

  Future<void> _logout() async {
    await LocalSessionStore.clear();
    if (!mounted) return;
    final deps = DependencyScope.of(context);
    deps.apiClient.clearAccessToken();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<_ProfileViewData>(
        future: _future,
        builder: (context, snap) {
          if (_future == null || snap.connectionState != ConnectionState.done) {
            return const _ProfileLoading();
          }
          if (snap.hasError) {
            return ApiErrorPlaceholder(
              message: snap.error.toString(),
              onRetry: _reload,
            );
          }
          final view = snap.data!;
          final p = view.profile;
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _reload,
            edgeOffset: 120,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _ProfileHeader(profile: p, onLogout: _logout),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _StatsStrip(profile: p),
                      const SizedBox(height: 14),
                      _SummarySection(profile: p),
                      const SizedBox(height: 14),
                      _InterestsSection(profile: p),
                      const SizedBox(height: 14),
                      _ActivitySection(history: view.history),
                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileViewData {
  const _ProfileViewData({required this.profile, required this.history});

  final UserProfile profile;
  final List<ProfileHistoryItem> history;
}

class _ProfileLoading extends StatelessWidget {
  const _ProfileLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Carregando seu perfil…',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunitySeal extends StatelessWidget {
  const _CommunitySeal({required this.community});

  final CommunityHighlight community;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip:
          'Destaque de comunidade: ${community.name} '
          '(${_communityKindLabel(community.kind)} - ${_communityRoleLabel(community.role)}).',
      onPressed: () {},
      style: IconButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      icon: const Icon(Icons.diversity_3_rounded),
    );
  }

  static String _communityKindLabel(CommunityKind kind) => switch (kind) {
    CommunityKind.athletic => 'Atletica',
    CommunityKind.academicCenter => 'CA',
    CommunityKind.community => 'Comunidade',
  };

  static String _communityRoleLabel(CommunityRole role) => switch (role) {
    CommunityRole.member => 'Membro',
    CommunityRole.director => 'Diretoria',
    CommunityRole.president => 'Presidencia',
  };
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onLogout});

  final UserProfile profile;
  final Future<void> Function() onLogout;

  static const _bannerDeep = Color(0xFF0F172A);
  static const _bannerMid = Color(0xFF1E3A8A);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    const bannerHeight = 118.0;
    const avatarR = 48.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: bannerHeight + topPad,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    profile.coverImageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    errorBuilder: (_, _, _) => Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_bannerDeep, _bannerMid, AppColors.primary],
                          stops: [0, 0.55, 1],
                        ),
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.52),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    right: -24,
                    top: topPad + 8,
                    child: IgnorePointer(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: topPad + 10,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: Row(
                        children: [
                          Text(
                            'Perfil',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white.withValues(alpha: 0.98),
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.14,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {},
                            icon: const Icon(Icons.share_outlined),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.14,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Sair da conta'),
                                  content: const Text(
                                    'Deseja encerrar sua sessao neste dispositivo?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancelar'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Sair'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await onLogout();
                              }
                            },
                            icon: const Icon(Icons.settings_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: topPad + bannerHeight - avatarR,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        profile.avatarImageUrl,
                        width: avatarR * 2,
                        height: avatarR * 2,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: avatarR * 2,
                          height: avatarR * 2,
                          color: AppColors.primary,
                          alignment: Alignment.center,
                          child: Text(
                            _initialsFor(profile.name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 26,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            width: avatarR * 2,
                            height: avatarR * 2,
                            color: AppColors.primary.withValues(alpha: 0.25),
                            alignment: Alignment.center,
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.primary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tagGroup.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.tagGroup.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_outlined,
                          size: 16,
                          color: AppColors.tagGroup,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Perfil verificado',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tagGroup,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, avatarR + 18, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  if (profile.communityHighlight != null) ...[
                    const SizedBox(width: 10),
                    _CommunitySeal(community: profile.communityHighlight!),
                  ],
                ],
              ),

              const SizedBox(height: 8),
              if (profile.jobTitle.trim().isNotEmpty) ...[
                Text(
                  profile.jobTitle,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.35,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                _courseSubtitle(profile),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary.withValues(alpha: 0.95),
                ),
              ),
              const SizedBox(height: 14),
              SoftCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _contactRow(Icons.mail_outline_rounded, profile.email),
                    Divider(
                      height: 20,
                      color: AppColors.chipBorder.withValues(alpha: 0.7),
                    ),
                    _contactRow(Icons.place_outlined, profile.cityState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _courseSubtitle(UserProfile profile) {
    final base = profile.course.trim();
    final semester = profile.semester.trim();
    if (base.isEmpty && semester.isEmpty) return 'Sem curso informado';
    if (base.isEmpty) return '$semester semestre';
    if (semester.isEmpty) return base;
    return '$base - $semester semestre';
  }

  String _initialsFor(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Widget _contactRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _statBlock(
              icon: Icons.description_outlined,
              value: '${profile.applicationsCount}',
              label: 'Candidaturas',
              tint: const Color(0xFF2563EB),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _statBlock(
              icon: Icons.groups_2_outlined,
              value: '${profile.groupsCount}',
              label: 'Grupos',
              tint: const Color(0xFF059669),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _statBlock(
              icon: Icons.event_available_outlined,
              value: '${profile.eventsCount}',
              label: 'Eventos',
              tint: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _vDivider() {
    return Container(
      width: 1,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.chipBorder.withValues(alpha: 0.75),
    );
  }

  Widget _statBlock({
    required IconData icon,
    required String value,
    required String label,
    required Color tint,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: tint),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline_rounded, color: AppColors.textPrimary),
              SizedBox(width: 8),
              Text(
                'Sobre o perfil',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (profile.aboutMe.trim().isNotEmpty)
            Text(
              profile.aboutMe,
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            )
          else
            Text(
              'Sem descricao no momento.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
          if (profile.institutionName.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 18,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    profile.institutionName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _InterestsSection extends StatelessWidget {
  const _InterestsSection({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Preferencias',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Gostos, topicos favoritos e especialidades do seu perfil.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          _TopicGroup(
            title: 'Interesses',
            items: profile.interests,
            tint: AppColors.primary,
          ),
          const SizedBox(height: 12),
          _TopicGroup(
            title: 'Topicos favoritos',
            items: profile.favoriteTopics,
            tint: const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 12),
          _TopicGroup(
            title: 'Especialidades',
            items: profile.specialties,
            tint: const Color(0xFF059669),
          ),
        ],
      ),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.history});

  final List<ProfileHistoryItem> history;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.timeline_outlined,
                color: AppColors.textPrimary,
                size: 22,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Painel de atividade',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Histórico recente visível apenas para você.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            Text(
              'Sem atividades recentes.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary.withValues(alpha: 0.85),
              ),
            )
          else
            ...history.map(_activityTile),
        ],
      ),
    );
  }

  Widget _activityTile(ProfileHistoryItem a) {
    final meta = switch (a.kind) {
      ProfileHistoryKind.post => (
        Icons.article_outlined,
        const Color(0xFF2563EB),
        'Post',
      ),
      ProfileHistoryKind.reading => (
        Icons.menu_book_outlined,
        const Color(0xFF7C3AED),
        'Leitura',
      ),
      ProfileHistoryKind.group => (
        Icons.groups_2_outlined,
        const Color(0xFF059669),
        'Grupo',
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.chipBorder.withValues(alpha: 0.65),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: meta.$2),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 44,
                          width: 44,
                          decoration: BoxDecoration(
                            color: meta.$2.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(meta.$1, color: meta.$2, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: meta.$2.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  meta.$3,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.4,
                                    color: meta.$2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: AppColors.textSecondary,
                                  ),
                                  children: [
                                    TextSpan(text: _prefixFor(a.kind)),
                                    TextSpan(
                                      text: a.title,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (a.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  a.subtitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.92,
                                    ),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule_rounded,
                                    size: 15,
                                    color: AppColors.textSecondary.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _timeAgoLabel(a.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary.withValues(
                                        alpha: 0.78,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _prefixFor(ProfileHistoryKind k) => switch (k) {
    ProfileHistoryKind.post => 'Post publicado: ',
    ProfileHistoryKind.reading => 'Leitura publicada: ',
    ProfileHistoryKind.group => 'Participacao em grupo: ',
  };

  String _timeAgoLabel(DateTime createdAt) {
    final now = DateTime.now().toUtc();
    final diff = now.difference(createdAt.toUtc());
    if (diff.inMinutes < 1) return 'Agora mesmo';
    if (diff.inHours < 1) return 'Ha ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Ha ${diff.inHours} h';
    if (diff.inDays < 30) return 'Ha ${diff.inDays} dias';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return 'Ha $months mes(es)';
    final years = (months / 12).floor();
    return 'Ha $years ano(s)';
  }
}

class _TopicGroup extends StatelessWidget {
  const _TopicGroup({
    required this.title,
    required this.items,
    required this.tint,
  });

  final String title;
  final List<String> items;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: tint,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Text(
            'Nenhum item informado.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary.withValues(alpha: 0.8),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: items
                .map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          tint.withValues(alpha: 0.12),
                          tint.withValues(alpha: 0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: tint.withValues(alpha: 0.18)),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: tint,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
      ],
    );
  }
}
