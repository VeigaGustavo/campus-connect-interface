/// Regras alinhadas a boas práticas de senha forte para cadastro.
abstract final class PasswordStrength {
  static const int minLength = 8;

  static PasswordStrengthResult analyze(String raw) {
    final s = raw;
    final hasMinLength = s.length >= minLength;
    final hasUpper = RegExp('[A-Z]').hasMatch(s);
    final hasLower = RegExp('[a-z]').hasMatch(s);
    final hasDigit = RegExp('[0-9]').hasMatch(s);
    final hasSpecial = RegExp(r'[^a-zA-Z0-9]').hasMatch(s);
    return PasswordStrengthResult(
      hasMinLength: hasMinLength,
      hasUpper: hasUpper,
      hasLower: hasLower,
      hasDigit: hasDigit,
      hasSpecial: hasSpecial,
    );
  }
}

class PasswordStrengthResult {
  const PasswordStrengthResult({
    required this.hasMinLength,
    required this.hasUpper,
    required this.hasLower,
    required this.hasDigit,
    required this.hasSpecial,
  });

  final bool hasMinLength;
  final bool hasUpper;
  final bool hasLower;
  final bool hasDigit;
  final bool hasSpecial;

  static const int _totalRules = 5;

  int get score => [
        hasMinLength,
        hasUpper,
        hasLower,
        hasDigit,
        hasSpecial,
      ].where((e) => e).length;

  double get fraction => score / _totalRules;

  bool get isStrong => score == _totalRules;
}
