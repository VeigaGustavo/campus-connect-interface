import 'package:campus_connect_interface/core/autenticacao/validacao_senha.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:flutter/material.dart';

/// Barra de progresso, critérios com check e legenda de senha forte.
class PasswordStrengthPanel extends StatelessWidget {
  const PasswordStrengthPanel({
    super.key,
    required this.analysis,
  });

  final PasswordStrengthResult analysis;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final level = _StrengthLevel.fromScore(analysis.score);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Força da senha',
          style: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: analysis.fraction,
            minHeight: 8,
            backgroundColor: AppColors.chipBorder.withValues(alpha: 0.5),
            color: level.color,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: level.color),
            const SizedBox(width: 6),
            Text(
              level.label,
              style: textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: level.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Uma senha forte inclui:',
          style: textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _ruleRow(
          textTheme,
          'Pelo menos ${PasswordStrength.minLength} caracteres',
          analysis.hasMinLength,
        ),
        _ruleRow(
          textTheme,
          'Uma letra maiúscula (A–Z)',
          analysis.hasUpper,
        ),
        _ruleRow(
          textTheme,
          'Uma letra minúscula (a–z)',
          analysis.hasLower,
        ),
        _ruleRow(
          textTheme,
          'Um número (0–9)',
          analysis.hasDigit,
        ),
        _ruleRow(
          textTheme,
          'Um símbolo ou caractere especial (ex.: ! @ # \$ % & *)',
          analysis.hasSpecial,
        ),
      ],
    );
  }

  Widget _ruleRow(TextTheme textTheme, String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            ok ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 18,
            color: ok ? const Color(0xFF059669) : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodySmall?.copyWith(
                color: ok ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: ok ? FontWeight.w600 : FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StrengthLevel {
  const _StrengthLevel(this.label, this.color);

  final String label;
  final Color color;

  static _StrengthLevel fromScore(int score) {
    if (score <= 0) {
      return const _StrengthLevel('—', AppColors.textSecondary);
    }
    if (score <= 2) {
      return const _StrengthLevel('Fraca', Color(0xFFDC2626));
    }
    if (score == 3) {
      return const _StrengthLevel('Média', Color(0xFFD97706));
    }
    if (score == 4) {
      return const _StrengthLevel('Boa', Color(0xFF2563EB));
    }
    return const _StrengthLevel('Forte', Color(0xFF059669));
  }
}
