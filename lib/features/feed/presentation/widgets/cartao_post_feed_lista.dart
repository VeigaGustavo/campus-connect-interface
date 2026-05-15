import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/util/formatacao_data_portugues.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';
import 'package:flutter/material.dart';

class FeedPostListCard extends StatelessWidget {
  const FeedPostListCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  final FeedPostDetail post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final kind = post.contentKindEnum;
    final previewImage = post.attachments
        .where((a) => a.type == FeedAttachmentType.image)
        .map((a) => a.url)
        .where((u) => u.isNotEmpty)
        .firstOrNull;

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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                      backgroundImage: post.author.avatarImageUrl.isNotEmpty
                          ? NetworkImage(post.author.avatarImageUrl)
                          : null,
                      child: post.author.avatarImageUrl.isEmpty
                          ? Text(
                              _initials(post.author.name),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                                fontSize: 13,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.author.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            formatDayMonthTimePt(post.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (kind != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          kind.labelPt,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
                if (post.text.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    post.text,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
                if (previewImage != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      previewImage,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                if (post.attachments.isNotEmpty &&
                    post.attachments.any(
                      (a) =>
                          a.type == FeedAttachmentType.link ||
                          a.type == FeedAttachmentType.video,
                    )) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: post.attachments
                        .where(
                          (a) =>
                              a.type == FeedAttachmentType.link ||
                              a.type == FeedAttachmentType.video,
                        )
                        .map(
                          (a) => Chip(
                            visualDensity: VisualDensity.compact,
                            avatar: Icon(
                              a.type == FeedAttachmentType.video
                                  ? Icons.videocam_outlined
                                  : Icons.link_rounded,
                              size: 16,
                            ),
                            label: Text(
                              a.name ?? a.url,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.thumb_up_alt_outlined,
                      size: 18,
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: AppColors.textSecondary.withValues(alpha: 0.85),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.comments.length}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                    const Spacer(),
                    if (post.publishScope == FeedPublishScope.group)
                      Text(
                        'Grupo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary.withValues(alpha: 0.85),
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

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
