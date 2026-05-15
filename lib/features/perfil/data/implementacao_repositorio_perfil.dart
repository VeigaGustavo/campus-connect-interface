import 'package:campus_connect_interface/core/configuracao/configuracao_api.dart';
import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/core/rede/url_midia_api.dart';
import 'package:campus_connect_interface/features/perfil/domain/repositorio_perfil.dart';
import 'package:campus_connect_interface/features/perfil/domain/perfil_usuario.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<UserProfile> getCurrentProfile() async {
    final raw = await _api.get('/api/profile', requiresAuth: true);
    if (raw == null) {
      throw StateError('Resposta de perfil vazia');
    }
    return _mapProfile(decodeJsonObject(raw));
  }

  @override
  Future<UserProfile> updateCurrentProfile(ProfileUpdateInput input) async {
    final payload = {
      'about_me': input.aboutMe,
      'job_title': input.jobTitle,
      'course': input.course,
      'semester': input.semester,
      'institution_name': input.institutionName,
      'map_url': input.mapUrl.trim(),
      'interests': _normalizeLabelList(input.interests),
      'favorite_topics': _normalizeLabelList(input.favoriteTopics),
      'specialties': _normalizeLabelList(input.specialties),
    };

    final raw = await _api.put(
      '/api/profile',
      body: payload,
      requiresAuth: true,
    );
    if (raw == null) {
      throw StateError('Resposta de atualização de perfil vazia');
    }
    return _mapProfile(decodeJsonObject(raw));
  }

  static MediaType _mediaTypeForFilename(String filename) {
    final f = filename.toLowerCase();
    if (f.endsWith('.png')) return MediaType('image', 'png');
    if (f.endsWith('.gif')) return MediaType('image', 'gif');
    if (f.endsWith('.webp')) return MediaType('image', 'webp');
    if (f.endsWith('.bmp')) return MediaType('image', 'bmp');
    return MediaType('image', 'jpeg');
  }

  /// Part único com bytes da imagem (nunca URL `blob:`). A API aceita também
  /// `file` / `image`; usamos `avatar` e `cover` como no contrato do backend.
  static List<http.MultipartFile> _multipartProfileImageParts({
    required String fieldName,
    required List<int> bytes,
    required String safeName,
    required MediaType contentType,
  }) {
    return [
      http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: safeName,
        contentType: contentType,
      ),
    ];
  }

  @override
  Future<UserProfile> uploadProfileAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Imagem vazia; nada para enviar.');
    }
    final safeName = filename.trim().isEmpty ? 'avatar.jpg' : filename;
    final ct = _mediaTypeForFilename(safeName);
    final raw = await _api.postMultipart(
      ApiConfig.profileAvatarUploadPath,
      files: _multipartProfileImageParts(
        fieldName: 'avatar',
        bytes: bytes,
        safeName: safeName,
        contentType: ct,
      ),
      requiresAuth: true,
    );
    return _profileAfterAvatarUpload(raw);
  }

  Future<UserProfile> _profileAfterAvatarUpload(dynamic uploadRaw) async {
    var profile = await getCurrentProfile();
    if (uploadRaw != null) {
      final m = decodeJsonObject(uploadRaw);
      final fromPost = mediaUrlFromJson(m, const [
        'avatar_image_url',
        'avatar_url',
        'avatar',
        'url',
      ]);
      if (fromPost.isNotEmpty) {
        profile = profile.copyWith(avatarImageUrl: fromPost);
      }
    }
    return profile;
  }

  Future<UserProfile> _profileAfterCoverUpload(dynamic uploadRaw) async {
    var profile = await getCurrentProfile();
    if (uploadRaw != null) {
      final m = decodeJsonObject(uploadRaw);
      final fromPost = mediaUrlFromJson(m, const [
        'cover_image_url',
        'cover_url',
        'cover',
        'url',
      ]);
      if (fromPost.isNotEmpty) {
        profile = profile.copyWith(coverImageUrl: fromPost);
      }
    }
    return profile;
  }

  @override
  Future<UserProfile> uploadProfileCover({
    required List<int> bytes,
    required String filename,
  }) async {
    if (bytes.isEmpty) {
      throw StateError('Imagem vazia; nada para enviar.');
    }
    final safeName = filename.trim().isEmpty ? 'cover.jpg' : filename;
    final ct = _mediaTypeForFilename(safeName);
    final raw = await _api.postMultipart(
      ApiConfig.profileCoverUploadPath,
      files: _multipartProfileImageParts(
        fieldName: 'cover',
        bytes: bytes,
        safeName: safeName,
        contentType: ct,
      ),
      requiresAuth: true,
    );
    return _profileAfterCoverUpload(raw);
  }

  @override
  Future<List<ProfileHistoryItem>> getCurrentUserHistory({
    int limit = 20,
  }) async {
    final safeLimit = limit <= 0 ? 20 : limit;
    final raw = await _api.get(
      '/api/profile/history',
      query: {'limit': '$safeLimit'},
      requiresAuth: true,
    );
    if (raw == null) {
      return const [];
    }
    final list = _decodeHistoryPayload(raw);
    return list
        .map((e) => _mapHistoryItem(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// Aceita lista JSON, `{ "items": [...] }` ou envelopes usuais (`data`, `history`, …).
  /// Objeto sem lista conhecida vira lista vazia (evita derrubar o perfil).
  static List<dynamic> _decodeHistoryPayload(dynamic raw) {
    if (raw is List<dynamic>) return raw;
    if (raw is Map<String, dynamic>) {
      const keys = <String>[
        'items',
        'data',
        'results',
        'history',
        'records',
      ];
      for (final k in keys) {
        final v = raw[k];
        if (v is List<dynamic>) return v;
      }
      return const [];
    }
    throw FormatException(
      'Historico: esperado lista ou objeto com lista (ex.: items).',
    );
  }

  static UserProfile _mapProfile(Map<String, dynamic> j) {
    final legacyType = AccountProfileType.fromApiValue(j['profile_type']);
    final profileContext = ProfileContext.fromApi(
      j['profile_context'],
      legacyProfileType: legacyType,
    );
    final profileType = AccountProfileType.fromProfilePayload(
      profileContext: profileContext,
      role: j['role'] ?? j['account_role'],
      profileType: j['profile_type'],
    );
    final CommunityHighlight? communityHighlight =
        profileContext == ProfileContext.organization
            ? null
            : _mapCommunityHighlight(j['community_highlight']);

    final OrganizationPanel? organizationPanel =
        profileContext == ProfileContext.organization
            ? _mapOrganizationPanel(j['organization_panel'])
            : null;

    return UserProfile(
      id: _stringOrEmpty(j['id']),
      profileContext: profileContext,
      profileType: profileType,
      name: _stringOrEmpty(j['name']),
      coverImageUrl: mediaUrlFromJson(j, const [
        'cover_image_url',
        'cover_url',
        'cover',
      ]),
      avatarImageUrl: mediaUrlFromJson(j, const [
        'avatar_image_url',
        'avatar_url',
        'avatar',
        'profile_image_url',
      ]),
      email: _stringOrEmpty(j['email']),
      cityState: _stringOrEmpty(j['city_state']),
      aboutMe: _stringOrEmpty(j['about_me']),
      jobTitle: _stringOrEmpty(j['job_title']),
      course: _stringOrEmpty(j['course']),
      semester: _stringOrEmpty(j['semester']),
      institutionName: _stringOrEmpty(j['institution_name']),
      applicationsCount: _toInt(j['applications_count']),
      groupsCount: _toInt(j['groups_count']),
      eventsCount: _toInt(j['events_count']),
      interests: _mapStringList(j['interests']),
      favoriteTopics: _mapStringList(j['favorite_topics']),
      specialties: _mapStringList(j['specialties']),
      communityHighlight: communityHighlight,
      organizationPanel: organizationPanel,
    );
  }

  static OrganizationPanel _mapOrganizationPanel(dynamic raw) {
    if (raw == null || raw is! Map) {
      return const OrganizationPanel();
    }
    final j = Map<String, dynamic>.from(raw);
    return OrganizationPanel(
      parentInstitution: _nullableNonEmptyString(j['parent_institution']),
      mapUrl: _nullableNonEmptyString(j['map_url']),
      jobs: _parseOrganizationListed(j['jobs']),
      events: _parseOrganizationListed(j['events']),
      groups: _parseOrganizationListed(j['groups']),
      posts: _parseOrganizationPosts(j['posts']),
      jobsTotal: _toInt(j['jobs_total']),
      eventsTotal: _toInt(j['events_total']),
      groupsTotal: _toInt(j['groups_total']),
      postsTotal: _toInt(j['posts_total']),
    );
  }

  static String? _nullableNonEmptyString(dynamic value) {
    final s = _stringOrEmpty(value).trim();
    return s.isEmpty ? null : s;
  }

  static List<OrganizationPanelListedItem> _parseOrganizationListed(
    dynamic raw,
  ) {
    if (raw is! List) return const [];
    final out = <OrganizationPanelListedItem>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      out.add(
        OrganizationPanelListedItem(
          id: _stringOrEmpty(m['id']),
          title: _stringOrEmpty(m['title']),
          subtitle: _stringOrEmpty(m['subtitle']),
          referenceId: _stringOrEmpty(m['reference_id']),
          createdAt:
              DateTime.tryParse(_stringOrEmpty(m['created_at'])) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
      );
    }
    return out;
  }

  static List<OrganizationPanelPost> _parseOrganizationPosts(dynamic raw) {
    if (raw is! List) return const [];
    final out = <OrganizationPanelPost>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final preview = _stringOrEmpty(m['preview']);
      final title = _stringOrEmpty(m['title']);
      final text = preview.isNotEmpty ? preview : title;
      out.add(
        OrganizationPanelPost(
          id: _stringOrEmpty(m['id']),
          preview: text,
          createdAt:
              DateTime.tryParse(_stringOrEmpty(m['created_at'])) ??
              DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        ),
      );
    }
    return out;
  }

  static ProfileHistoryItem _mapHistoryItem(Map<String, dynamic> j) {
    return ProfileHistoryItem(
      id: _stringOrEmpty(j['id']),
      kind: _parseHistoryKind(_stringOrEmpty(j['kind'])),
      title: _stringOrEmpty(j['title']),
      subtitle: _stringOrEmpty(j['subtitle']),
      referenceId: _stringOrEmpty(j['reference_id']),
      createdAt:
          DateTime.tryParse(_stringOrEmpty(j['created_at'])) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  static CommunityHighlight? _mapCommunityHighlight(dynamic value) {
    if (value == null) return null;
    final j = value as Map<String, dynamic>;
    return CommunityHighlight(
      id: _stringOrEmpty(j['id']),
      name: _stringOrEmpty(j['name']),
      kind: _parseCommunityKind(_stringOrEmpty(j['kind'])),
      role: _parseCommunityRole(_stringOrEmpty(j['role'])),
    );
  }

  static List<String> _mapStringList(dynamic v) {
    if (v is! List) return [];
    return v
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _normalizeLabelList(List<String> values) {
    final result = <String>[];
    final seen = <String>{};

    for (final raw in values) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.length > 50) {
        throw FormatException('Itens devem ter no máximo 50 caracteres');
      }
      final key = trimmed.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      result.add(trimmed);
      if (result.length == 20) break;
    }
    return result;
  }

  static ProfileHistoryKind _parseHistoryKind(String s) => switch (s) {
    'post' => ProfileHistoryKind.post,
    'reading' => ProfileHistoryKind.reading,
    'group' => ProfileHistoryKind.group,
    _ => throw FormatException('history kind desconhecido: $s'),
  };

  static CommunityKind _parseCommunityKind(String s) => switch (s) {
    'athletic' => CommunityKind.athletic,
    'academic_center' => CommunityKind.academicCenter,
    'community' => CommunityKind.community,
    _ => throw FormatException('community kind desconhecido: $s'),
  };

  static CommunityRole _parseCommunityRole(String s) => switch (s) {
    'member' => CommunityRole.member,
    'director' => CommunityRole.director,
    'president' => CommunityRole.president,
    _ => throw FormatException('community role desconhecido: $s'),
  };

  static String _stringOrEmpty(dynamic value) => value is String ? value : '';

  static int _toInt(dynamic value) => switch (value) {
    int v => v,
    num v => v.toInt(),
    _ => 0,
  };
}
