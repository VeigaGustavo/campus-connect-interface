enum GroupLevel { beginner, intermediate, advanced }

extension GroupLevelX on GroupLevel {
  String get labelPt => switch (this) {
    GroupLevel.beginner => 'Iniciante',
    GroupLevel.intermediate => 'Intermediário',
    GroupLevel.advanced => 'Avançado',
  };
}
