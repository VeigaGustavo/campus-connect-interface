import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/features/perfil/domain/repositorio_perfil.dart';
import 'package:campus_connect_interface/features/perfil/domain/perfil_usuario.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<UserProfile> getCurrentProfile() async {
    final raw = await _api.get('/api/profile');
    if (raw == null) {
      throw StateError('Resposta de perfil vazia');
    }
    return _mapProfile(decodeJsonObject(raw));
  }

  static UserProfile _mapProfile(Map<String, dynamic> j) {
    final interestsRaw = j['interests'];
    final activityRaw = j['recent_activity'];
    return UserProfile(
      name: j['name'] as String,
      initials: j['initials'] as String,
      coverImageUrl: j['cover_image_url'] as String,
      avatarImageUrl: j['avatar_image_url'] as String,
      performanceCertificateLabel:
          j['performance_certificate_label'] as String,
      courseAndSemester: j['course_and_semester'] as String,
      email: j['email'] as String,
      cityState: j['city_state'] as String,
      applicationsCount: (j['applications_count'] as num).toInt(),
      groupsCount: (j['groups_count'] as num).toInt(),
      eventsCount: (j['events_count'] as num).toInt(),
      interests: _mapInterests(interestsRaw),
      recentActivity: _mapActivities(activityRaw),
    );
  }

  static List<UserInterest> _mapInterests(dynamic v) {
    if (v is! List) return [];
    return v.map((e) {
      if (e is String) return UserInterest(e);
      if (e is Map<String, dynamic>) {
        return UserInterest(e['label'] as String);
      }
      throw FormatException('interests: item inválido');
    }).toList();
  }

  static List<ProfileActivity> _mapActivities(dynamic v) {
    if (v is! List) return [];
    return v.map((e) => _mapActivity(e as Map<String, dynamic>)).toList();
  }

  static ProfileActivity _mapActivity(Map<String, dynamic> j) {
    return ProfileActivity(
      kind: _parseActivityKind(j['kind'] as String),
      titleHighlight: j['title_highlight'] as String,
      subtitle: j['subtitle'] as String,
      timeAgoLabel: j['time_ago_label'] as String,
    );
  }

  static ProfileActivityKind _parseActivityKind(String s) => switch (s) {
        'application' => ProfileActivityKind.application,
        'group_joined' => ProfileActivityKind.groupJoined,
        'event_registered' => ProfileActivityKind.eventRegistered,
        _ =>
          throw FormatException('activity kind desconhecido: $s'),
      };
}
