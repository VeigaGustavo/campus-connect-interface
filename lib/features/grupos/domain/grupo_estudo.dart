import 'package:campus_connect_interface/features/grupos/domain/nivel_grupo.dart';

class StudyGroup {
  const StudyGroup({
    required this.id,
    required this.title,
    required this.fieldOfStudy,
    required this.description,
    required this.level,
    required this.memberCount,
    required this.scheduleLabel,
    this.visibility = 'public',
  });

  final String id;
  final String title;
  final String fieldOfStudy;
  final String description;
  final GroupLevel level;
  final int memberCount;
  final String scheduleLabel;
  final String visibility;

  bool get isPrivate => visibility == 'private';
}
