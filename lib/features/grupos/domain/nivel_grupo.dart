enum GroupLevel { beginner, intermediate, advanced }

extension GroupLevelX on GroupLevel {
  String get labelPt => switch (this) {
        GroupLevel.beginner => 'Iniciante',
        GroupLevel.intermediate => 'Intermediário',
        GroupLevel.advanced => 'Avançado',
      };

  String get apiValue => switch (this) {
        GroupLevel.beginner => 'beginner',
        GroupLevel.intermediate => 'intermediate',
        GroupLevel.advanced => 'advanced',
      };

  static GroupLevel fromApi(String raw) => switch (raw) {
        'intermediate' => GroupLevel.intermediate,
        'advanced' => GroupLevel.advanced,
        _ => GroupLevel.beginner,
      };
}
