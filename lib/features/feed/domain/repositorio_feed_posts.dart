import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';

enum FeedAttachmentType { image, video, file }

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
  final int likesCount;
  final int dislikesCount;
  final List<PostComment> comments;
  final FeedReaction myReaction;
  final bool saved;
  final String shareLink;
  final DateTime createdAt;
}

class CreatePostRequest {
  const CreatePostRequest({
    required this.text,
    this.attachments = const [],
    this.publishScope = FeedPublishScope.all,
    this.publishGroupId,
  });

  final String text;
  final List<FeedAttachment> attachments;
  final FeedPublishScope publishScope;
  final String? publishGroupId;
}

abstract class FeedPostsRepository {
  Future<FeedPostDetail> getPostById(String id);
  Future<List<PostComment>> listComments(String postId);
  Future<PostComment> createComment(String postId, String text);
  Future<void> reactToPost(String postId, FeedReaction reaction);
  Future<void> reactToComment(String commentId, FeedReaction reaction);
  Future<void> setSaved(String postId, bool saved);
  Future<FeedPostDetail> createPost(CreatePostRequest request);
}
