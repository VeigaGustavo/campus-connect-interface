import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:flutter/material.dart';

class SearchableSelectionField extends StatelessWidget {
  const SearchableSelectionField({
    super.key,
    required this.label,
    required this.options,
    required this.onSelected,
    this.value,
    this.icon,
    this.hintText,
    this.enabled = true,
  });

  final String label;
  final List<String> options;
  final String? value;
  final ValueChanged<String> onSelected;
  final IconData? icon;
  final String? hintText;
  final bool enabled;

  List<String> _filter(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return options;
    return options.where((o) => o.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      optionsBuilder: (query) => _filter(query.text),
      displayStringForOption: (o) => o,
      initialValue: (value != null && value!.isNotEmpty)
          ? TextEditingValue(text: value!)
          : null,
      onSelected: onSelected,
      fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          onChanged: (v) => onSelected(v.trim()),
          onSubmitted: (_) => onFieldSubmitted(),
          decoration: InputDecoration(
            labelText: label,
            hintText: hintText ?? 'Buscar ou selecionar',
            prefixIcon: icon != null ? Icon(icon) : null,
            suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
            filled: true,
            fillColor: AppColors.background.withValues(alpha: 0.65),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.chipBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.chipBorder.withValues(alpha: 0.9),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
            ),
          ),
        );
      },
      optionsViewBuilder: (context, onSelected, iterable) {
        final items = iterable.toList();
        final width = MediaQuery.sizeOf(context).width - 72;
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(12),
            color: AppColors.surface,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 240, maxWidth: width),
              child: items.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Nenhum resultado. Ajuste a busca.',
                        style: TextStyle(
                          color: AppColors.textSecondary.withValues(alpha: 0.9),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      shrinkWrap: true,
                      itemCount: items.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: AppColors.chipBorder.withValues(alpha: 0.5),
                      ),
                      itemBuilder: (context, index) {
                        final option = items[index];
                        return ListTile(
                          dense: true,
                          title: Text(
                            option,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          onTap: () => onSelected(option),
                        );
                      },
                    ),
            ),
          ),
        );
      },
    );
  }
}
