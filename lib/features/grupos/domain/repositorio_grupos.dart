import 'package:campus_connect_interface/features/grupos/domain/grupo_estudo.dart';

abstract class GroupsRepository {
  Future<List<StudyGroup>> listGroups();
}
