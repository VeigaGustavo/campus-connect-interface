import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';
import 'package:flutter/material.dart';

class FeedPostDetailScreen extends StatefulWidget {
  const FeedPostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<FeedPostDetailScreen> createState() => _FeedPostDetailScreenState();
}

class _FeedPostDetailScreenState extends State<FeedPostDetailScreen> {
  Future<FeedPostDetail>? _future;
  final _commentController = TextEditingController();
  bool _sendingComment = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<FeedPostDetail> _load() {
    final repo = DependencyScope.of(context).feedPostsRepository;
    return repo.getPostById(widget.postId);
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _future = next);
    await next;
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sendingComment) return;
    final repo = DependencyScope.of(context).feedPostsRepository;
    setState(() => _sendingComment = true);
    try {
      await repo.createComment(widget.postId, text);
      _commentController.clear();
      await _reload();
    } finally {
      if (mounted) setState(() => _sendingComment = false);
    }
  }

  Future<void> _react(FeedReaction reaction) async {
    final repo = DependencyScope.of(context).feedPostsRepository;
    await repo.reactToPost(widget.postId, reaction);
    await _reload();
  }

  Future<void> _toggleSaved(bool value) async {
    final repo = DependencyScope.of(context).feedPostsRepository;
    await repo.setSaved(widget.postId, value);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Post'),
        leading: const BackButton(),
      ),
      body: FutureBuilder<FeedPostDetail>(
        future: _future,
        builder: (context, snap) {
          if (_future == null || snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(
              child: Text(
                'Falha ao carregar o post',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          final post = snap.data!;
          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    children: [
                      _PostHeader(
                        post: post,
                        onLike: () => _react(
                          post.myReaction == FeedReaction.like
                              ? FeedReaction.none
                              : FeedReaction.like,
                        ),
                        onDislike: () => _react(
                          post.myReaction == FeedReaction.dislike
                              ? FeedReaction.none
                              : FeedReaction.dislike,
                        ),
                        onSavedChanged: _toggleSaved,
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Comentários',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...post.comments.map((c) => _CommentTile(comment: c)),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Escreva um comentário',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: _sendingComment ? null : _sendComment,
                        child: _sendingComment
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Enviar'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({
    required this.post,
    required this.onLike,
    required this.onDislike,
    required this.onSavedChanged,
  });

  final FeedPostDetail post;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final ValueChanged<bool> onSavedChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.chipBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.author.name,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.text,
              style: const TextStyle(
                fontSize: 15,
                height: 1.35,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.attachments
                  .map((a) => Chip(label: Text('${a.type.name}: ${a.url}')))
                  .toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                IconButton(
                  onPressed: onLike,
                  icon: Icon(
                    Icons.thumb_up_alt_outlined,
                    color: post.myReaction == FeedReaction.like
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                Text('${post.likesCount}'),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: onDislike,
                  icon: Icon(
                    Icons.thumb_down_alt_outlined,
                    color: post.myReaction == FeedReaction.dislike
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
                Text('${post.dislikesCount}'),
                const Spacer(),
                IconButton(
                  onPressed: () => onSavedChanged(!post.saved),
                  icon: Icon(
                    post.saved ? Icons.bookmark : Icons.bookmark_border,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final PostComment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.chipBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                comment.author.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                comment.text,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
