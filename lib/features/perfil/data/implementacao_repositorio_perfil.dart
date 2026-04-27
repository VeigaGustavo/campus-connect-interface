import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/features/perfil/domain/repositorio_perfil.dart';
import 'package:campus_connect_interface/features/perfil/domain/perfil_usuario.dart';

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
    final list = decodeJsonList(raw);
    return list
        .map((e) => _mapHistoryItem(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  static UserProfile _mapProfile(Map<String, dynamic> j) {
    return UserProfile(
      id: _stringOrEmpty(j['id']),
      name: _stringOrEmpty(j['name']),
      coverImageUrl: _stringOrEmpty(j['cover_image_url']),
      avatarImageUrl: _stringOrEmpty(j['avatar_image_url']),
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
      communityHighlight: _mapCommunityHighlight(j['community_highlight']),
    );
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
