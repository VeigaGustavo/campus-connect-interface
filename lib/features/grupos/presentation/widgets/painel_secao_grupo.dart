import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';
import 'package:campus_connect_interface/features/feed/presentation/widgets/cartao_post_feed_lista.dart';
import 'package:campus_connect_interface/features/grupos/domain/secao_detalhe_grupo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GroupSectionPanel extends StatelessWidget {
  const GroupSectionPanel({
    super.key,
    required this.section,
    required this.loading,
    required this.error,
    required this.posts,
    required this.events,
    required this.memberCount,
    required this.chatAuthorIds,
    required this.onRetry,
  });

  final GroupDetailSection section;
  final bool loading;
  final String? error;
  final List<FeedPostDetail> posts;
  final List<Map<String, dynamic>> events;
  final int memberCount;
  final Set<String> chatAuthorIds;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
            ],
          ),
        ),
      );
    }

    return switch (section) {
      GroupDetailSection.members => _members(),
      GroupDetailSection.events => _events(),
      _ => _postsList(context),
    };
  }

  Widget _members() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$memberCount membros',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                chatAuthorIds.isEmpty
                    ? 'A API de membros será integrada em breve. Por enquanto, veja quem participou do chat.'
                    : '${chatAuthorIds.length} pessoa(s) enviaram mensagens no chat.',
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        if (chatAuthorIds.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Ativos no chat',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...chatAuthorIds.map(
            (id) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SoftCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      id.length >= 2 ? id.substring(0, 2).toUpperCase() : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  title: Text('Participante'),
                  subtitle: Text(
                    id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _events() {
    if (events.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum evento vinculado a este grupo.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: events.length,
      itemBuilder: (context, i) {
        final e = events[i];
        final eventId = (e['event_id'] ?? e['id'] ?? '').toString();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SoftCard(
            child: ListTile(
              leading: const Icon(Icons.event_available_outlined),
              title: Text('Evento $eventId'),
              subtitle: Text('Associação: ${e['id'] ?? ''}'),
            ),
          ),
        );
      },
    );
  }

  Widget _postsList(BuildContext context) {
    if (posts.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma publicação em ${section.titlePt.toLowerCase()}.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: posts.length,
      itemBuilder: (context, i) {
        final post = posts[i];
        return FeedPostListCard(
          post: post,
          onTap: () => context.push('/feed/posts/${post.id}'),
        );
      },
    );
  }
}
