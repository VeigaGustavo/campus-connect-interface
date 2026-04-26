import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/inicio/domain/item_descoberta.dart';
import 'package:campus_connect_interface/features/inicio/domain/tipo_item_descoberta.dart';
import 'package:flutter/material.dart';

class DiscoverCard extends StatelessWidget {
  const DiscoverCard({super.key, required this.item, this.onTap});

  final DiscoverItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tag = _tagFor(item.kind);
    final visibility = item.visibilityLabel;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: SoftCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: tag.$1.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tag.$2, size: 16, color: tag.$1),
                          const SizedBox(width: 6),
                          Text(
                            tag.$3,
                            style: TextStyle(
                              color: tag.$1,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (visibility != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.chipBorder),
                        ),
                        child: Text(
                          visibility,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  item.excerpt,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.35,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.metaPrimary,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 16,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.metaSecondary,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, IconData, String) _tagFor(DiscoverKind k) => switch (k) {
    DiscoverKind.post => (
      AppColors.primary,
      Icons.forum_outlined,
      'Posts',
    ),
    DiscoverKind.opportunity => (
      AppColors.tagInternship,
      Icons.work_outline_rounded,
      'Vagas',
    ),
    DiscoverKind.event => (
      AppColors.tagEvent,
      Icons.event_outlined,
      'Eventos',
    ),
    DiscoverKind.studyGroup => (
      AppColors.tagGroup,
      Icons.groups_2_outlined,
      'Grupos de Estudo',
    ),
    DiscoverKind.project => (
      AppColors.tagProject,
      Icons.lightbulb_outline_rounded,
      'Projetos',
    ),
    DiscoverKind.reading => (
      AppColors.tagReading,
      Icons.auto_stories_outlined,
      'Leituras',
    ),
    DiscoverKind.notice => (
      AppColors.tagNotice,
      Icons.campaign_outlined,
      'Avisos',
    ),
  };
}
