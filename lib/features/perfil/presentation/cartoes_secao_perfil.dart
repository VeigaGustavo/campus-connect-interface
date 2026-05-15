import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/perfil/domain/perfil_usuario.dart';
import 'package:flutter/material.dart';

/// Rótulo de período/semestre para exibição no perfil.
String formatProfilePeriodLabel(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  final lower = s.toLowerCase();
  if (lower.contains('semestre') ||
      lower.contains('período') ||
      lower.contains('periodo')) {
    return s;
  }
  return '$sº semestre';
}

IconData _aboutCardLeadingIcon(AccountProfileType t) => switch (t) {
      AccountProfileType.estudante => Icons.person_outline_rounded,
      AccountProfileType.comunidade => Icons.groups_3_rounded,
      AccountProfileType.empresa => Icons.apartment_rounded,
      AccountProfileType.universidade => Icons.account_balance_rounded,
    };

IconData _institutionDetailIcon(AccountProfileType t) => switch (t) {
      AccountProfileType.estudante => Icons.school_outlined,
      AccountProfileType.comunidade => Icons.info_outline_rounded,
      AccountProfileType.empresa => Icons.badge_outlined,
      AccountProfileType.universidade => Icons.school_outlined,
    };

bool _showInstitutionDetailRow(UserProfile profile) {
  if (!profile.isOrganizationProfile) return false;
  final n = profile.institutionName.trim();
  if (n.isEmpty) return false;
  if (n.toLowerCase() == profile.name.trim().toLowerCase()) {
    return false;
  }
  return true;
}

class ProfileAboutCard extends StatelessWidget {
  const ProfileAboutCard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _aboutCardLeadingIcon(profile.profileType),
                color: AppColors.textPrimary,
              ),
              const SizedBox(width: 8),
              Text(
                profile.profileType.aboutCardTitle,
                style: const TextStyle(
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
              profile.profileType.emptyAboutFallback,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary.withValues(alpha: 0.9),
              ),
            ),
          if (_showInstitutionDetailRow(profile)) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  _institutionDetailIcon(profile.profileType),
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

class ProfilePreferencesCard extends StatelessWidget {
  const ProfilePreferencesCard({super.key, required this.profile});

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
                'Preferências',
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
            profile.profileType.preferencesSubtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const gap = 10.0;
              const minColumnWidth = 108.0;
              final columns = [
                ProfileKanbanColumn(
                  title: 'Interesses',
                  items: profile.interests,
                  tint: AppColors.primary,
                ),
                ProfileKanbanColumn(
                  title: 'Topicos favoritos',
                  items: profile.favoriteTopics,
                  tint: const Color(0xFF0EA5E9),
                ),
                ProfileKanbanColumn(
                  title: 'Especialidades',
                  items: profile.specialties,
                  tint: const Color(0xFF059669),
                ),
              ];
              final fitsInRow =
                  constraints.maxWidth >= minColumnWidth * 3 + gap * 2;

              if (fitsInRow) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < columns.length; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Expanded(child: columns[i]),
                    ],
                  ],
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < columns.length; i++) ...[
                        if (i > 0) const SizedBox(width: gap),
                        SizedBox(width: minColumnWidth, child: columns[i]),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProfileActivityPanelCard extends StatelessWidget {
  const ProfileActivityPanelCard({
    super.key,
    required this.history,
    required this.profileType,
  });

  final List<ProfileHistoryItem> history;
  final AccountProfileType profileType;

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
            profileType.activityPrivacyLine,
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

  static String _prefixFor(ProfileHistoryKind k) => switch (k) {
    ProfileHistoryKind.post => 'Post publicado: ',
    ProfileHistoryKind.reading => 'Leitura publicada: ',
    ProfileHistoryKind.group => 'Participacao em grupo: ',
  };

  static String _timeAgoLabel(DateTime createdAt) {
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

/// Coluna estilo Kanban (Trello): cabeçalho + cartões empilhados verticalmente.
class ProfileKanbanColumn extends StatelessWidget {
  const ProfileKanbanColumn({
    super.key,
    required this.title,
    required this.items,
    required this.tint,
  });

  final String title;
  final List<String> items;
  final Color tint;

  static const _columnBg = Color(0xFFF1F5F9);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _columnBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.chipBorder.withValues(alpha: 0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                      color: tint,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${items.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: tint,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
            child: items.isEmpty
                ? _emptyPlaceholder()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0) const SizedBox(height: 8),
                        _KanbanCard(label: items[i], tint: tint),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _emptyPlaceholder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.chipBorder.withValues(alpha: 0.5),
          style: BorderStyle.solid,
        ),
      ),
      child: Text(
        'Nenhum item',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary.withValues(alpha: 0.75),
        ),
      ),
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({required this.label, required this.tint});

  final String label;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.chipBorder.withValues(alpha: 0.85)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.3,
          color: tint,
        ),
      ),
    );
  }
}
