import 'package:campus_connect_interface/features/grupos/domain/grupo_estudo.dart';
import 'package:campus_connect_interface/features/grupos/domain/mensagem_chat_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/requisicao_criar_grupo.dart';

abstract class GroupsRepository {
  Future<List<StudyGroup>> listGroups();

  Future<StudyGroup> createGroup(CreateStudyGroupRequest request);

  Future<List<GroupChatMessage>> listChatMessages(String groupId);

  Future<GroupChatMessage> sendChatMessage(String groupId, String text);

  Future<List<Map<String, dynamic>>> listLinkedEvents(String groupId);
}
