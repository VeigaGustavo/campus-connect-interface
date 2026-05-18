import 'package:campus_connect_interface/core/configuracao/configuracao_api.dart';
import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/core/rede/url_midia_api.dart';
import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FeedPostsRepositoryImpl implements FeedPostsRepository {
  FeedPostsRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<FeedPostsPage> listPosts(FeedPostsQuery query) async {
    final safeLimit = query.limit.clamp(1, 50);
    final params = <String, String>{
      'page': '${query.page.clamp(1, 9999)}',
      'limit': '$safeLimit',
      if (query.includeComments) 'include_comments': 'true',
      if (query.authorId != null && query.authorId!.trim().isNotEmpty)
        'author_id': query.authorId!.trim(),
    };
    final groupIds = query.groupIds
        ?.map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    if (groupIds != null && groupIds.isNotEmpty) {
      params['group_ids'] = groupIds.join(',');
    }

    final raw = await _api.get(
      '/api/feed/posts',
      query: params,
      requiresAuth: true,
    );
    final body = decodeJsonObject(raw);
    final itemsRaw = body['items'];
    final items = itemsRaw is List
        ? itemsRaw
            .whereType<Map>()
            .map((e) => _mapPost(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : <FeedPostDetail>[];

    return FeedPostsPage(
      items: items,
      total: _toInt(body['total']),
      page: _toInt(body['page'], fallback: query.page),
      limit: _toInt(body['limit'], fallback: safeLimit),
      hasMore: body['has_more'] == true,
    );
  }

  @override
  Future<FeedPostDetail> getPostById(String id) async {
    final raw = await _api.get(
      '/api/feed/posts/$id',
      requiresAuth: true,
    );
    return _mapPost(decodeJsonObject(raw));
  }

  static int _toInt(dynamic value, {int fallback = 0}) => switch (value) {
        int v => v,
        num v => v.toInt(),
        _ => fallback,
      };

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
    final contentKind = request.contentKind.apiValue;
    final raw = await _api.post(
      '/api/feed/posts',
      body: {
        'text': request.text,
        'attachments': request.attachments
            .map((a) => {
                  'type': _attachmentTypeToApi(a.type),
                  'url': a.url,
                  if (a.name != null && a.name!.isNotEmpty) 'name': a.name,
                })
            .toList(),
        'publish_scope':
            request.publishScope == FeedPublishScope.group ? 'group' : 'all',
        if (request.publishGroupId != null &&
            request.publishGroupId!.isNotEmpty)
          'publish_group_id': request.publishGroupId,
        'content_kind': ?contentKind,
      },
      requiresAuth: true,
    );
    return _mapPost(decodeJsonObject(raw));
  }

  @override
  Future<FeedAttachment> uploadAttachment({
    required List<int> bytes,
    required String filename,
    required FeedAttachmentType type,
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Ficheiro vazio; nada para enviar.');
    }
    if (type != FeedAttachmentType.image && type != FeedAttachmentType.video) {
      throw ArgumentError('Upload suporta apenas image ou video.');
    }
    final safeName = filename.trim().isEmpty
        ? (type == FeedAttachmentType.video ? 'video.mp4' : 'image.jpg')
        : filename;
    final raw = await _api.postMultipart(
      ApiConfig.feedAttachmentUploadPath,
      fields: {'type': _attachmentTypeToApi(type)},
      files: [
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: safeName,
          contentType: _mediaTypeForFilename(safeName, type),
        ),
      ],
      requiresAuth: true,
    );
    if (raw == null) {
      throw StateError('Resposta de upload de anexo vazia.');
    }
    return _mapUploadedAttachment(decodeJsonObject(raw), fallbackType: type);
  }

  static MediaType _mediaTypeForFilename(String filename, FeedAttachmentType type) {
    final f = filename.toLowerCase();
    if (type == FeedAttachmentType.video) {
      if (f.endsWith('.webm')) return MediaType('video', 'webm');
      if (f.endsWith('.mov')) return MediaType('video', 'quicktime');
      return MediaType('video', 'mp4');
    }
    if (f.endsWith('.png')) return MediaType('image', 'png');
    if (f.endsWith('.gif')) return MediaType('image', 'gif');
    if (f.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  static FeedAttachment _mapUploadedAttachment(
    Map<String, dynamic> j, {
    required FeedAttachmentType fallbackType,
  }) {
    final url = mediaUrlFromJson(j, const ['url', 'file_url', 'media_url']);
    if (url.isEmpty) {
      throw FormatException('Upload sem URL na resposta.');
    }
    final typeRaw = (j['type'] ?? '').toString();
    final type = typeRaw.isEmpty
        ? fallbackType
        : _parseAttachmentType(typeRaw);
    final name = (j['name'] ?? j['filename'] ?? '').toString().trim();
    return FeedAttachment(
      type: type,
      url: url,
      name: name.isEmpty ? null : name,
    );
  }

  static FeedPostDetail _mapPost(Map<String, dynamic> j) {
    final commentsRaw = j['comments'];
    final comments = commentsRaw is List
        ? commentsRaw
            .whereType<Map>()
            .map((e) => _mapComment(Map<String, dynamic>.from(e)))
            .toList(growable: false)
        : <PostComment>[];
    final authorRaw = j['author'];
    final author = authorRaw is Map
        ? _mapAuthor(Map<String, dynamic>.from(authorRaw))
        : FeedAuthor(
            id: j['author_id']?.toString() ?? '',
            name: 'Usuário',
            avatarImageUrl: '',
            role: AppUserRole.padrao,
          );
    final scopeRaw = (j['publish_scope'] ?? 'all').toString();
    final groupId = (j['publish_group_id'] ?? '').toString().trim();

    return FeedPostDetail(
      id: j['id'].toString(),
      authorId: j['author_id']?.toString() ?? author.id,
      author: author,
      text: (j['text'] ?? j['body_text'] ?? '') as String,
      attachments: _mapAttachments(j['attachments']),
      contentKind: (j['content_kind'] ?? '').toString(),
      publishScope: scopeRaw == 'group'
          ? FeedPublishScope.group
          : FeedPublishScope.all,
      publishGroupId: groupId.isEmpty ? null : groupId,
      likesCount: (j['likes_count'] as num?)?.toInt() ?? 0,
      dislikesCount: (j['dislikes_count'] as num?)?.toInt() ?? 0,
      comments: comments,
      myReaction: _parseReaction((j['my_reaction'] ?? '').toString()),
      saved: j['saved'] == true,
      shareLink: (j['share_link'] ?? '').toString(),
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  static List<FeedAttachment> _mapAttachments(dynamic raw) {
    if (raw == null) return const [];
    final list = decodeJsonList(raw);
    return list.map((e) {
      final j = e as Map<String, dynamic>;
      final nameRaw = j['name'];
      final name = nameRaw is String && nameRaw.trim().isNotEmpty
          ? nameRaw.trim()
          : null;
      return FeedAttachment(
        type: _parseAttachmentType((j['type'] ?? 'file').toString()),
        url: resolveApiMediaUrl((j['url'] ?? '').toString()),
        name: name,
      );
    }).toList();
  }

  static FeedAuthor _mapAuthor(Map<String, dynamic> j) {
    return FeedAuthor(
      id: j['id'].toString(),
      name: (j['name'] ?? '') as String,
      avatarImageUrl: mediaUrlFromJson(j, const [
        'avatar_image_url',
        'avatar_url',
        'avatar',
      ]),
      role: AppUserRole.fromValue((j['role'] ?? 'padrao').toString()),
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
        'link' => FeedAttachmentType.link,
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
        FeedAttachmentType.link => 'link',
        FeedAttachmentType.file => 'file',
      };
}
