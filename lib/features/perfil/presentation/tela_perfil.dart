import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/mensagem_erro_api.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/perfil/domain/perfil_usuario.dart';
import 'package:campus_connect_interface/features/perfil/presentation/cartao_painel_organizacao.dart';
import 'package:campus_connect_interface/features/perfil/presentation/cartoes_secao_perfil.dart';
import 'package:campus_connect_interface/features/perfil/presentation/modal_configuracoes_perfil.dart';
import 'package:campus_connect_interface/features/perfil/presentation/widget_imagem_midia_perfil.dart';
import 'package:flutter/material.dart';

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

  Future<void> _openSettings() async {
    final updated = await showProfileSettingsModal(context);
    if (updated == true && mounted) await _reload();
  }

  Future<_ProfileViewData> _loadProfileView() async {
    final repo = DependencyScope.of(context).profileRepository;
    final profile = await repo.getCurrentProfile();
    return _ProfileViewData(profile: profile);
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
                  child: _ProfileHeader(
                    profile: p,
                    onOpenSettings: _openSettings,
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _StatsStrip(profile: p),
                      const SizedBox(height: 14),
                      if (p.profileType == AccountProfileType.estudante)
                        ProfilePreferencesCard(profile: p),
                      if (p.profileType == AccountProfileType.comunidade) ...[
                        ProfileAboutCard(profile: p),
                        const SizedBox(height: 14),
                        ProfileCommunityAccountCard(profile: p),
                      ] else if (p.isOrganizationProfile) ...[
                        ProfileAboutCard(profile: p),
                      ],
                      if (p.isOrganizationProfile) ...[
                        const SizedBox(height: 14),
                        OrganizationPanelCard(
                          panel:
                              p.organizationPanel ?? const OrganizationPanel(),
                          profileType: p.profileType,
                        ),
                      ],
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
  const _ProfileViewData({required this.profile});

  final UserProfile profile;
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
            'Carregando informações…',
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

class _AccountTypeChip extends StatelessWidget {
  const _AccountTypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: 0.1,
          ),
        ),
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

class _StudentAcademicCard extends StatelessWidget {
  const _StudentAcademicCard({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final institution = profile.institutionName.trim();
    final course = profile.course.trim();
    final period = formatProfilePeriodLabel(profile.semester);

    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _cell(
                icon: Icons.account_balance_outlined,
                label: 'Instituição',
                value: institution.isNotEmpty ? institution : 'Não informada',
              ),
            ),
            _divider(),
            Expanded(
              child: _cell(
                icon: Icons.school_outlined,
                label: 'Graduação',
                value: course.isNotEmpty ? course : 'Não informada',
              ),
            ),
            _divider(),
            Expanded(
              child: _cell(
                icon: Icons.calendar_month_outlined,
                label: 'Período',
                value: period.isNotEmpty ? period : 'Não informado',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: AppColors.chipBorder.withValues(alpha: 0.85),
      ),
    );
  }

  Widget _cell({
    required IconData icon,
    required String label,
    required String value,
  }) {
    final isPlaceholder =
        value == 'Não informada' || value == 'Não informado';
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          height: 32,
          width: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 17, color: AppColors.primary),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: isPlaceholder
                ? AppColors.textSecondary.withValues(alpha: 0.75)
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.onOpenSettings,
  });

  final UserProfile profile;
  final Future<void> Function() onOpenSettings;

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
                  ProfileMediaImage(
                    url: profile.coverImageUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    error: Container(
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
                            profile.profileType.shellBarTitle,
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
                            onPressed: onOpenSettings,
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
                      child: ProfileMediaImage(
                        url: profile.avatarImageUrl,
                        width: avatarR * 2,
                        height: avatarR * 2,
                        fit: BoxFit.cover,
                        error: Container(
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
                        placeholder: Container(
                          width: avatarR * 2,
                          height: avatarR * 2,
                          color: AppColors.primary.withValues(alpha: 0.25),
                          alignment: Alignment.center,
                          child: SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.primary.withValues(alpha: 0.85),
                            ),
                          ),
                        ),
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
                          profile.profileType.verifiedBadgeLabel,
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
                  if (profile.communityHighlight != null &&
                      !profile.isOrganizationProfile) ...[
                    const SizedBox(width: 10),
                    _CommunitySeal(community: profile.communityHighlight!),
                  ],
                ],
              ),

              const SizedBox(height: 8),
              if (profile.isOrganizationProfile) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _AccountTypeChip(label: profile.profileType.kindChipLabel),
                    if (profile.profileType == AccountProfileType.comunidade &&
                        profile.communityTypeLabel != null)
                      _AccountTypeChip(label: profile.communityTypeLabel!),
                  ],
                ),
                const SizedBox(height: 10),
              ],
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
              if (profile.isOrganizationProfile) ...[
                if (_institutionSubtitleLine(profile).isNotEmpty)
                  Text(
                    _institutionSubtitleLine(profile),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary.withValues(alpha: 0.95),
                    ),
                  ),
              ] else ...[
                _StudentAcademicCard(profile: profile),
                const SizedBox(height: 14),
                ProfileAboutCard(profile: profile),
              ],
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

  String _institutionSubtitleLine(UserProfile profile) {
    final loc = profile.cityState.trim();
    if (loc.isNotEmpty) return loc;
    final extra = profile.institutionName.trim();
    final name = profile.name.trim();
    if (extra.isNotEmpty && extra.toLowerCase() != name.toLowerCase()) {
      return extra;
    }
    return '';
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
    if (!profile.isOrganizationProfile) {
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

    final p = profile.organizationPanel ?? const OrganizationPanel();
    final t = profile.profileType;

    Widget orgRow(List<Widget> children) {
      return SoftCard(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        child: Row(children: children),
      );
    }

    switch (t) {
      case AccountProfileType.empresa:
        return orgRow([
          Expanded(
            child: _statBlock(
              icon: Icons.work_outline_rounded,
              value: '${p.jobsTotal}',
              label: 'Vagas',
              tint: const Color(0xFF2563EB),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _statBlock(
              icon: Icons.event_available_outlined,
              value: '${p.eventsTotal}',
              label: 'Eventos',
              tint: const Color(0xFF7C3AED),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _statBlock(
              icon: Icons.article_outlined,
              value: '${p.postsTotal}',
              label: 'Posts',
              tint: const Color(0xFF0891B2),
            ),
          ),
        ]);
      case AccountProfileType.universidade:
        final mapOk = p.mapUrl != null && p.mapUrl!.trim().isNotEmpty;
        return orgRow([
          Expanded(
            child: _statBlock(
              icon: Icons.event_available_outlined,
              value: '${p.eventsTotal}',
              label: 'Eventos',
              tint: const Color(0xFF7C3AED),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _statBlock(
              icon: Icons.article_outlined,
              value: '${p.postsTotal}',
              label: 'Posts',
              tint: const Color(0xFF0891B2),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _statBlock(
              icon: Icons.map_outlined,
              value: mapOk ? '1' : '0',
              label: 'Mapa',
              tint: const Color(0xFF059669),
            ),
          ),
        ]);
      case AccountProfileType.comunidade:
        return orgRow([
          Expanded(
            child: _statBlock(
              icon: Icons.groups_2_outlined,
              value: '${p.groupsTotal}',
              label: 'Grupos',
              tint: const Color(0xFF059669),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _statBlock(
              icon: Icons.event_available_outlined,
              value: '${p.eventsTotal}',
              label: 'Eventos',
              tint: const Color(0xFF7C3AED),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _statBlock(
              icon: Icons.article_outlined,
              value: '${p.postsTotal}',
              label: 'Posts',
              tint: const Color(0xFF0891B2),
            ),
          ),
        ]);
      case AccountProfileType.estudante:
        return orgRow([
          Expanded(
            child: _statBlock(
              icon: Icons.groups_2_outlined,
              value: '${p.groupsTotal}',
              label: 'Grupos',
              tint: const Color(0xFF059669),
            ),
          ),
          _vDivider(),
          Expanded(
            child: _statBlock(
              icon: Icons.event_available_outlined,
              value: '${p.eventsTotal}',
              label: 'Eventos',
              tint: const Color(0xFF7C3AED),
            ),
          ),
        ]);
    }
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
