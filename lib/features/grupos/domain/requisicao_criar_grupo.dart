import 'package:campus_connect_interface/features/grupos/domain/nivel_grupo.dart';

class CreateStudyGroupRequest {
  const CreateStudyGroupRequest({
    required this.title,
    required this.fieldOfStudy,
    required this.description,
    this.level = GroupLevel.beginner,
    this.visibility = 'public',
    this.scheduleLabel = '',
  });

  final String title;
  final String fieldOfStudy;
  final String description;
  final GroupLevel level;
  final String visibility;
  final String scheduleLabel;

  Map<String, dynamic> toJson() => {
        'title': title,
        'field_of_study': fieldOfStudy,
        'description': description,
        'level': level.apiValue,
        'schedule_label': scheduleLabel,
        'visibility': visibility,
      };
}
