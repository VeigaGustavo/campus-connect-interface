import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/rede/excecao_api.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/snackbar_erro_api.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/grupos/domain/nivel_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/requisicao_criar_grupo.dart';
import 'package:flutter/material.dart';

Future<bool?> showCreateStudyGroupModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const CreateStudyGroupSheet(),
  );
}

class CreateStudyGroupSheet extends StatefulWidget {
  const CreateStudyGroupSheet({super.key});

  @override
  State<CreateStudyGroupSheet> createState() => _CreateStudyGroupSheetState();
}

class _CreateStudyGroupSheetState extends State<CreateStudyGroupSheet> {
  final _title = TextEditingController();
  final _field = TextEditingController();
  final _description = TextEditingController();
  GroupLevel _level = GroupLevel.beginner;
  String _visibility = 'public';
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _field.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final repo = DependencyScope.of(context).groupsRepository;
      await repo.createGroup(
        CreateStudyGroupRequest(
          title: _title.text.trim(),
          fieldOfStudy: _field.text.trim(),
          description: _description.text.trim(),
          level: _level,
          visibility: _visibility,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      showApiErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.88,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Material(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.chipBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Novo grupo',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    children: [
                      SoftCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                controller: _title,
                                decoration: const InputDecoration(
                                  labelText: 'Nome do grupo',
                                  prefixIcon: Icon(Icons.groups_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _field,
                                decoration: const InputDecoration(
                                  labelText: 'Área / disciplina',
                                  hintText: 'Ex.: Cálculo I, Direito Civil',
                                  prefixIcon: Icon(Icons.menu_book_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _description,
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Descrição',
                                  alignLabelWithHint: true,
                                  prefixIcon: Icon(Icons.notes_outlined),
                                ),
                              ),
                              const SizedBox(height: 16),
                              DropdownButtonFormField<GroupLevel>(
                                value: _level,
                                decoration: const InputDecoration(
                                  labelText: 'Nível',
                                  prefixIcon: Icon(Icons.school_outlined),
                                ),
                                items: GroupLevel.values
                                    .map(
                                      (l) => DropdownMenuItem(
                                        value: l,
                                        child: Text(l.labelPt),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _submitting
                                    ? null
                                    : (v) => setState(
                                          () => _level = v ?? GroupLevel.beginner,
                                        ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Visibilidade',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SegmentedButton<String>(
                                segments: const [
                                  ButtonSegment(
                                    value: 'public',
                                    label: Text('Público'),
                                    icon: Icon(Icons.public_outlined, size: 18),
                                  ),
                                  ButtonSegment(
                                    value: 'private',
                                    label: Text('Privado'),
                                    icon: Icon(Icons.lock_outline, size: 18),
                                  ),
                                ],
                                selected: {_visibility},
                                onSelectionChanged: _submitting
                                    ? null
                                    : (s) => setState(
                                          () => _visibility = s.first,
                                        ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Criar grupo'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
