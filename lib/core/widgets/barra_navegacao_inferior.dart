import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:flutter/material.dart';

class CampusBottomNav extends StatelessWidget {
  const CampusBottomNav({
    super.key,
    required this.currentIndex,
    required this.onBranchSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onBranchSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _item(Icons.home_outlined, 'Início', 0),
              _item(Icons.work_outline_rounded, 'Oportunidades', 1),
              _item(Icons.menu_book_outlined, 'Leituras', 2),
              _item(Icons.groups_2_outlined, 'Grupos', 3),
              _item(Icons.person_outline_rounded, 'Perfil', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, String label, int index) {
    final selected = currentIndex == index;
    final color = selected ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: () => onBranchSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
