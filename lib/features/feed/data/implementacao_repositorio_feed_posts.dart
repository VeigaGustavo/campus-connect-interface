import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';

class FeedPostsRepositoryImpl implements FeedPostsRepository {
  FeedPostsRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<FeedPostDetail> getPostById(String id) async {
    final raw = await _api.get('/api/feed/posts/$id');
    return _mapPost(decodeJsonObject(raw));
  }

  @override
  Future<List<PostComment>> listComments(String postId) async {
    final raw = await _api.get('/api/feed/posts/$postId/comments');
    final list = decodeJsonList(raw);
    return list.map((e) => _mapComment(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<PostComment> createComment(String postId, String text) async {
    final raw = await _api.post(
      '/api/feed/posts/$postId/comments',
      body: {'text': text},
    );
    return _mapComment(decodeJsonObject(raw));
  }

  @override
  Future<void> reactToPost(String postId, FeedReaction reaction) async {
    await _api.put(
      '/api/feed/posts/$postId/reaction',
      body: {'reaction': _reactionToApi(reaction)},
    );
  }

  @override
  Future<void> reactToComment(String commentId, FeedReaction reaction) async {
    await _api.put(
      '/api/feed/comments/$commentId/reaction',
      body: {'reaction': _reactionToApi(reaction)},
    );
  }

  @override
  Future<void> setSaved(String postId, bool saved) async {
    await _api.put('/api/feed/posts/$postId/save', body: {'saved': saved});
  }

  @override
  Future<FeedPostDetail> createPost(CreatePostRequest request) async {
    final raw = await _api.post('/api/feed/posts', body: {
      'text': request.text,
      'attachments': request.attachments
          .map((a) => {
                'type': _attachmentTypeToApi(a.type),
                'url': a.url,
                if (a.name != null && a.name!.isNotEmpty) 'name': a.name,
              })
          .toList(),
      'publish_scope': request.publishScope == FeedPublishScope.group ? 'group' : 'all',
      if (request.publishGroupId != null && request.publishGroupId!.isNotEmpty)
        'publish_group_id': request.publishGroupId,
    });
    return _mapPost(decodeJsonObject(raw));
  }

  static FeedPostDetail _mapPost(Map<String, dynamic> j) {
    final comments = decodeJsonList(j['comments'])
        .map((e) => _mapComment(e as Map<String, dynamic>))
        .toList();
    return FeedPostDetail(
      id: j['id'].toString(),
      authorId: j['author_id'].toString(),
      author: _mapAuthor(j['author'] as Map<String, dynamic>),
      text: (j['text'] ?? '') as String,
      attachments: _mapAttachments(j['attachments']),
      likesCount: (j['likes_count'] as num?)?.toInt() ?? 0,
      dislikesCount: (j['dislikes_count'] as num?)?.toInt() ?? 0,
      comments: comments,
      myReaction: _parseReaction((j['my_reaction'] ?? '') as String),
      saved: (j['saved'] as bool?) ?? false,
      shareLink: (j['share_link'] ?? '') as String,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }

  static List<FeedAttachment> _mapAttachments(dynamic raw) {
    if (raw == null) return const [];
    final list = decodeJsonList(raw);
    return list.map((e) {
      final j = e as Map<String, dynamic>;
      return FeedAttachment(
        type: _parseAttachmentType(j['type'] as String),
        url: j['url'] as String,
        name: j['name'] as String?,
      );
    }).toList();
  }

  static FeedAuthor _mapAuthor(Map<String, dynamic> j) {
    return FeedAuthor(
      id: j['id'].toString(),
      name: j['name'] as String,
      avatarImageUrl: (j['avatar_image_url'] ?? '') as String,
      role: AppUserRole.fromValue((j['role'] ?? 'padrao') as String),
    );
  }

  static PostComment _mapComment(Map<String, dynamic> j) {
    return PostComment(
      id: j['id'].toString(),
      postId: j['post_id'].toString(),
      authorId: j['author_id'].toString(),
      author: _mapAuthor(j['author'] as Map<String, dynamic>),
      text: j['text'] as String,
      likesCount: (j['likes_count'] as num?)?.toInt() ?? 0,
      dislikesCount: (j['dislikes_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }

  static FeedReaction _parseReaction(String raw) => switch (raw) {
        'like' => FeedReaction.like,
        'dislike' => FeedReaction.dislike,
        _ => FeedReaction.none,
      };

  static FeedAttachmentType _parseAttachmentType(String raw) => switch (raw) {
        'image' => FeedAttachmentType.image,
        'video' => FeedAttachmentType.video,
        'file' => FeedAttachmentType.file,
        _ => FeedAttachmentType.file,
      };

  static String _reactionToApi(FeedReaction reaction) => switch (reaction) {
        FeedReaction.like => 'like',
        FeedReaction.dislike => 'dislike',
        FeedReaction.none => '',
      };

  static String _attachmentTypeToApi(FeedAttachmentType type) => switch (type) {
        FeedAttachmentType.image => 'image',
        FeedAttachmentType.video => 'video',
        FeedAttachmentType.file => 'file',
      };
}
