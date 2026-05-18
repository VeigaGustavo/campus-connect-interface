import 'package:campus_connect_interface/features/oportunidades/domain/modalidade_trabalho.dart';

class Opportunity {
  const Opportunity({
    required this.id,
    required this.title,
    required this.companyName,
    required this.shortDescription,
    required this.fullDescription,
    required this.applyDeadline,
    required this.workLocation,
    required this.typeLabel,
    required this.requirements,
  });

  final String id;
  final String title;
  final String companyName;
  final String shortDescription;
  final String fullDescription;
  final DateTime applyDeadline;
  final WorkLocation workLocation;
  final String typeLabel;
  final List<String> requirements;
}
