import 'package:campus_connect_interface/features/grupos/domain/grupo_estudo.dart';
import 'package:campus_connect_interface/features/grupos/domain/painel_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/secao_detalhe_grupo.dart';

class GroupSectionRouteArgs {
  const GroupSectionRouteArgs({
    required this.group,
    required this.panel,
    required this.section,
  });

  final StudyGroup? group;
  final GroupContentPanel? panel;
  final GroupDetailSection section;
}
