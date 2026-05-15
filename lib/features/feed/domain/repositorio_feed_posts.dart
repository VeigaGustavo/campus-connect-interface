import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';

enum FeedAttachmentType { image, video, link, file }

enum FeedReaction { like, dislike, none }

enum FeedPublishScope { all, group }

class FeedAuthor {
  const FeedAuthor({
    required this.id,
    required this.name,
    required this.avatarImageUrl,
    required this.role,
  });

  final String id;
  final String name;
  final String avatarImageUrl;
  final AppUserRole role;
}

class FeedAttachment {
  const FeedAttachment({
    required this.type,
    required this.url,
    this.name,
  });

  final FeedAttachmentType type;
  final String url;
  final String? name;
}

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.author,
    required this.text,
    required this.likesCount,
    required this.dislikesCount,
    required this.createdAt,
  });

  final String id;
  final String postId;
  final String authorId;
  final FeedAuthor author;
  final String text;
  final int likesCount;
  final int dislikesCount;
  final DateTime createdAt;
}

class FeedPostDetail {
  const FeedPostDetail({
    required this.id,
    required this.authorId,
    required this.author,
    required this.text,
    required this.attachments,
    required this.contentKind,
    required this.publishScope,
    required this.publishGroupId,
    required this.likesCount,
    required this.dislikesCount,
    required this.comments,
    required this.myReaction,
    required this.saved,
    required this.shareLink,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final FeedAuthor author;
  final String text;
  final List<FeedAttachment> attachments;
  final String contentKind;
  final FeedPublishScope publishScope;
  final String? publishGroupId;
  final int likesCount;
  final int dislikesCount;
  final List<PostComment> comments;
  final FeedReaction myReaction;
  final bool saved;
  final String shareLink;
  final DateTime createdAt;

  FeedPostContentKind? get contentKindEnum {
    final k = contentKind.trim();
    if (k.isEmpty) return null;
    return switch (k) {
      'article' => FeedPostContentKind.article,
      'campus_news' => FeedPostContentKind.campusNews,
      'magazine' => FeedPostContentKind.magazine,
      'notice' => FeedPostContentKind.notice,
      'project' => FeedPostContentKind.project,
      _ => null,
    };
  }
}

/// Parâmetros de `GET /api/feed/posts`.
class FeedPostsQuery {
  const FeedPostsQuery({
    this.page = 1,
    this.limit = 20,
    this.groupIds,
    this.authorId,
    this.includeComments = false,
  });

  final int page;
  final int limit;
  final List<String>? groupIds;
  final String? authorId;
  final bool includeComments;
}

class FeedPostsPage {
  const FeedPostsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.hasMore,
  });

  final List<FeedPostDetail> items;
  final int total;
  final int page;
  final int limit;
  final bool hasMore;
}

/// Tipo opcional do conteúdo. [FeedPostContentKind.simple] = post sem classificação.
enum FeedPostContentKind {
  simple,
  article,
  campusNews,
  magazine,
  notice,
  project;

  String? get apiValue => switch (this) {
        FeedPostContentKind.simple => null,
        FeedPostContentKind.article => 'article',
        FeedPostContentKind.campusNews => 'campus_news',
        FeedPostContentKind.magazine => 'magazine',
        FeedPostContentKind.notice => 'notice',
        FeedPostContentKind.project => 'project',
      };

  String get labelPt => switch (this) {
        FeedPostContentKind.simple => 'Post simples',
        FeedPostContentKind.article => 'Artigo',
        FeedPostContentKind.campusNews => 'Notícia',
        FeedPostContentKind.magazine => 'Revista',
        FeedPostContentKind.notice => 'Aviso',
        FeedPostContentKind.project => 'Projeto',
      };
}

class CreatePostRequest {
  const CreatePostRequest({
    required this.text,
    this.attachments = const [],
    this.publishScope = FeedPublishScope.all,
    this.publishGroupId,
    this.contentKind = FeedPostContentKind.simple,
  });

  final String text;
  final List<FeedAttachment> attachments;
  final FeedPublishScope publishScope;
  final String? publishGroupId;
  final FeedPostContentKind contentKind;
}

abstract class FeedPostsRepository {
  Future<FeedPostsPage> listPosts(FeedPostsQuery query);

  Future<FeedPostDetail> getPostById(String id);
  Future<List<PostComment>> listComments(String postId);
  Future<PostComment> createComment(String postId, String text);
  Future<void> reactToPost(String postId, FeedReaction reaction);
  Future<void> reactToComment(String commentId, FeedReaction reaction);
  Future<void> setSaved(String postId, bool saved);
  Future<FeedPostDetail> createPost(CreatePostRequest request);

  /// Envia ficheiro (imagem/vídeo) e devolve URL para incluir em [CreatePostRequest.attachments].
  Future<FeedAttachment> uploadAttachment({
    required List<int> bytes,
    required String filename,
    required FeedAttachmentType type,
  });
}
