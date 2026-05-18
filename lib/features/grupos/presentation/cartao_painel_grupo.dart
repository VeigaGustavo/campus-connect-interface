import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';
import 'package:campus_connect_interface/features/grupos/domain/painel_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/secao_detalhe_grupo.dart';
import 'package:flutter/material.dart';

typedef GroupSectionTap = void Function(GroupDetailSection section);

class GroupPanelCard extends StatelessWidget {
  const GroupPanelCard({
    super.key,
    required this.panel,
    required this.onOpenSection,
    this.memberCount = 0,
  });

  final GroupContentPanel panel;
  final GroupSectionTap onOpenSection;
  final int memberCount;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_customize_outlined,
                color: AppColors.primary.withValues(alpha: 0.95),
                size: 22,
              ),
              const SizedBox(width: 8),
              const Text(
                'Painel do grupo',
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
            'Toque em uma seção para ver a lista completa.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          _sectionTile(
            context,
            section: GroupDetailSection.members,
            title: 'Participantes',
            total: memberCount > 0
                ? memberCount
                : panel.chatMemberIds.length,
            icon: Icons.groups_2_outlined,
            preview: panel.chatMemberIds
                .take(3)
                .map(
                  (id) => GroupPanelListItem(
                    id: id,
                    title: 'Participante',
                    subtitle: id.length > 12 ? '${id.substring(0, 12)}…' : id,
                  ),
                )
                .toList(),
          ),
          _sectionTile(
            context,
            section: GroupDetailSection.posts,
            title: 'Publicações',
            total: panel.postsTotal,
            icon: Icons.dynamic_feed_outlined,
            preview: _postPreviews(panel.postsFor(null)),
          ),
          _sectionTile(
            context,
            section: GroupDetailSection.articles,
            title: 'Artigos',
            total: panel.articlesTotal,
            icon: Icons.article_outlined,
            preview: _postPreviews(panel.postsFor('article')),
          ),
          _sectionTile(
            context,
            section: GroupDetailSection.notices,
            title: 'Avisos',
            total: panel.noticesTotal,
            icon: Icons.campaign_outlined,
            preview: _postPreviews(panel.postsFor('notice')),
          ),
          _sectionTile(
            context,
            section: GroupDetailSection.news,
            title: 'Notícias',
            total: panel.newsTotal,
            icon: Icons.newspaper_outlined,
            preview: _postPreviews(panel.postsFor('campus_news')),
          ),
          _sectionTile(
            context,
            section: GroupDetailSection.projects,
            title: 'Projetos',
            total: panel.projectsTotal,
            icon: Icons.lightbulb_outline_rounded,
            preview: _postPreviews(panel.postsFor('project')),
          ),
          _sectionTile(
            context,
            section: GroupDetailSection.magazine,
            title: 'Revistas',
            total: panel.magazineTotal,
            icon: Icons.menu_book_outlined,
            preview: _postPreviews(panel.postsFor('magazine')),
          ),
          _sectionTile(
            context,
            section: GroupDetailSection.events,
            title: 'Eventos',
            total: panel.eventsTotal,
            icon: Icons.event_available_outlined,
            preview: panel.events
                .take(3)
                .map(
                  (e) => GroupPanelListItem(
                    id: (e['event_id'] ?? e['id'] ?? '').toString(),
                    title: 'Evento',
                    subtitle: (e['id'] ?? '').toString(),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  List<GroupPanelListItem> _postPreviews(List<FeedPostDetail> posts) {
    return posts
        .take(3)
        .map(
          (p) => GroupPanelListItem(
            id: p.id,
            title: p.text.length > 80 ? '${p.text.substring(0, 80)}…' : p.text,
            subtitle: '',
          ),
        )
        .toList();
  }

  Widget _sectionTile(
    BuildContext context, {
    required GroupDetailSection section,
    required String title,
    required int total,
    required IconData icon,
    required List<GroupPanelListItem> preview,
  }) {
    if (total == 0 && preview.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 14),
        child: InkWell(
          onTap: () => onOpenSection(section),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  '$title (0)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onOpenSection(section),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      '$title ($total)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ],
                ),
                if (preview.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Nenhum item na amostra.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.85),
                      ),
                    ),
                  )
                else
                  ...preview.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.chipBorder.withValues(alpha: 0.65),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.title.isNotEmpty ? e.title : '(sem título)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (e.subtitle.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                e.subtitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary
                                      .withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ],
                        ),
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
}
