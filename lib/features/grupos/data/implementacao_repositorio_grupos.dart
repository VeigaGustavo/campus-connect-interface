import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/features/grupos/domain/nivel_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/repositorio_grupos.dart';
import 'package:campus_connect_interface/features/grupos/domain/grupo_estudo.dart';
import 'package:campus_connect_interface/features/grupos/domain/mensagem_chat_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/requisicao_criar_grupo.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  GroupsRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<List<StudyGroup>> listGroups() async {
    final raw = await _api.get('/api/groups', requiresAuth: true);
    final list = decodeJsonListEnvelope(raw);
    return list
        .whereType<Map<String, dynamic>>()
        .map(_map)
        .toList(growable: false);
  }

  @override
  Future<StudyGroup> createGroup(CreateStudyGroupRequest request) async {
    final raw = await _api.createGroup(request.toJson());
    return _map(raw);
  }

  @override
  Future<List<GroupChatMessage>> listChatMessages(String groupId) async {
    try {
      final raw = await _api.listGroupChatMessages(groupId);
      return raw.map(_mapChat).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<GroupChatMessage> sendChatMessage(String groupId, String text) async {
    final raw = await _api.createGroupChatMessage(groupId, text);
    return _mapChat(raw);
  }

  @override
  Future<List<Map<String, dynamic>>> listLinkedEvents(String groupId) async {
    return _api.listGroupEvents(groupId);
  }

  static GroupChatMessage _mapChat(Map<String, dynamic> j) {
    var authorName = j['author_name']?.toString().trim();
    final author = j['author'];
    if ((authorName == null || authorName.isEmpty) &&
        author is Map<String, dynamic>) {
      authorName = (author['name'] ?? author['nome'])?.toString().trim();
    }

    return GroupChatMessage(
      id: j['id']?.toString() ?? '',
      groupId: j['group_id']?.toString() ?? '',
      authorId: j['author_id']?.toString() ?? '',
      text: (j['text'] ?? '') as String,
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()) ??
          DateTime.now(),
      authorName:
          authorName != null && authorName.isNotEmpty ? authorName : null,
    );
  }

  static StudyGroup _map(Map<String, dynamic> j) {
    return StudyGroup(
      id: j['id']?.toString() ?? '',
      title: (j['title'] ?? '') as String,
      fieldOfStudy: (j['field_of_study'] ?? '') as String,
      description: (j['description'] ?? '') as String,
      level: _parseLevel(j['level']),
      memberCount: (j['member_count'] as num?)?.toInt() ?? 0,
      scheduleLabel: (j['schedule_label'] ?? '') as String,
      visibility: (j['visibility'] ?? 'public') as String,
    );
  }

  static GroupLevel _parseLevel(dynamic raw) {
    final s = raw?.toString() ?? 'beginner';
    return switch (s) {
      'beginner' => GroupLevel.beginner,
      'intermediate' => GroupLevel.intermediate,
      'advanced' => GroupLevel.advanced,
      _ => GroupLevel.beginner,
    };
  }
}
