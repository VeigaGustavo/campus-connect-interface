import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/snackbar_erro_api.dart';
import 'package:flutter/material.dart';

const int kMaxProfileTagsPerList = 20;
const int kMaxProfileTagLength = 50;

List<String> normalizeProfileTagList(Iterable<String> raw) {
  final seen = <String>{};
  final out = <String>[];
  for (final item in raw) {
    final t = item.trim();
    if (t.isEmpty) continue;
    final key = t.toLowerCase();
    if (seen.contains(key)) continue;
    seen.add(key);
    out.add(
      t.length > kMaxProfileTagLength ? t.substring(0, kMaxProfileTagLength) : t,
    );
    if (out.length >= kMaxProfileTagsPerList) break;
  }
  return out;
}

class ProfileTagListEditor extends StatefulWidget {
  const ProfileTagListEditor({
    super.key,
    required this.title,
    required this.items,
    required this.tint,
    required this.onChanged,
    this.inputHint = 'Ex.: Flutter, APIs, UX',
    this.helpText =
        'Enter ou vírgula para adicionar. Remova com o ×. Salve no topo para publicar.',
  });

  final String title;
  final List<String> items;
  final Color tint;
  final ValueChanged<List<String>> onChanged;
  final String inputHint;
  final String helpText;

  @override
  State<ProfileTagListEditor> createState() => _ProfileTagListEditorState();
}

class _ProfileTagListEditorState extends State<ProfileTagListEditor> {
  late List<String> _items;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _focused = false;

  bool get _atLimit => _items.length >= kMaxProfileTagsPerList;

  @override
  void initState() {
    super.initState();
    _items = List<String>.from(widget.items);
    _focusNode.addListener(() {
      if (_focusNode.hasFocus != _focused) {
        setState(() => _focused = _focusNode.hasFocus);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ProfileTagListEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_listEquals(oldWidget.items, widget.items)) {
      _items = List<String>.from(widget.items);
    }
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(List<String>.from(_items));

  void _showLimitMessage() {
    showFloatingSnackBarMaybe(
      context,
      'Limite de 20 itens (máx. 50 caracteres cada).',
      duration: const Duration(seconds: 2),
    );
  }

  bool _addSingle(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return false;
    if (_atLimit) {
      _showLimitMessage();
      return false;
    }
    final next = normalizeProfileTagList([..._items, t]);
    if (next.length == _items.length) {
      showFloatingSnackBarMaybe(
        context,
        'Este item já está na lista.',
        duration: const Duration(seconds: 2),
      );
      return false;
    }
    setState(() => _items = next);
    _notify();
    return true;
  }

  void _commitInput() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;

    final parts = text.split(RegExp(r'[,;]'));
    var added = false;
    for (final part in parts) {
      if (_addSingle(part)) added = true;
      if (_atLimit) break;
    }
    _controller.clear();
    if (added) _focusNode.requestFocus();
  }

  void _remove(String item) {
    setState(() => _items = _items.where((e) => e != item).toList());
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? widget.tint
        : AppColors.chipBorder.withValues(alpha: 0.9);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: widget.tint,
                ),
              ),
            ),
            Text(
              '${_items.length}/$kMaxProfileTagsPerList',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary.withValues(alpha: 0.75),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _atLimit ? null : () => _focusNode.requestFocus(),
            borderRadius: BorderRadius.circular(12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ..._items.map(_chip),
                  if (!_atLimit)
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 140, maxWidth: 280),
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: _items.isEmpty
                              ? widget.inputHint
                              : 'Adicionar outro…',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary.withValues(alpha: 0.55),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _commitInput(),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.helpText,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.3,
                  color: AppColors.textSecondary.withValues(alpha: 0.78),
                ),
              ),
            ),
            if (!_atLimit && _controller.text.trim().isNotEmpty) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _commitInput,
                style: TextButton.styleFrom(
                  foregroundColor: widget.tint,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Adicionar',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _chip(String label) {
    return Container(
      padding: const EdgeInsets.only(left: 12, right: 4, top: 6, bottom: 6),
      decoration: BoxDecoration(
        color: widget.tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.tint.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: widget.tint.withValues(alpha: 0.95),
              ),
            ),
          ),
          const SizedBox(width: 2),
          Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => _remove(label),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: widget.tint.withValues(alpha: 0.85),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
