import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/features/grupos/domain/nivel_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/repositorio_grupos.dart';
import 'package:campus_connect_interface/features/grupos/domain/grupo_estudo.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  GroupsRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<List<StudyGroup>> listGroups() async {
    final raw = await _api.get('/api/groups');
    final list = decodeJsonList(raw);
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  static StudyGroup _map(Map<String, dynamic> j) {
    return StudyGroup(
      id: j['id'].toString(),
      title: j['title'] as String,
      fieldOfStudy: j['field_of_study'] as String,
      description: j['description'] as String,
      level: _parseLevel(j['level'] as String),
      memberCount: (j['member_count'] as num).toInt(),
      scheduleLabel: j['schedule_label'] as String,
    );
  }

  static GroupLevel _parseLevel(String s) => switch (s) {
        'beginner' => GroupLevel.beginner,
        'intermediate' => GroupLevel.intermediate,
        'advanced' => GroupLevel.advanced,
        _ => throw FormatException('level desconhecido: $s'),
      };
}
