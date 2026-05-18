import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/rede/excecao_api.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/snackbar_erro_api.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/leituras/domain/item_leitura_semanal.dart';
import 'package:campus_connect_interface/features/leituras/domain/requisicao_criar_leitura.dart';
import 'package:flutter/material.dart';

Future<bool?> showCreateWeeklyReadingModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const CreateWeeklyReadingSheet(),
  );
}

class CreateWeeklyReadingSheet extends StatefulWidget {
  const CreateWeeklyReadingSheet({super.key});

  @override
  State<CreateWeeklyReadingSheet> createState() => _CreateWeeklyReadingSheetState();
}

class _CreateWeeklyReadingSheetState extends State<CreateWeeklyReadingSheet> {
  final _title = TextEditingController();
  final _source = TextEditingController();
  final _excerpt = TextEditingController();
  final _imageUrl = TextEditingController();
  WeeklyReadingKind _kind = WeeklyReadingKind.magazine;
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _source.dispose();
    _excerpt.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await DependencyScope.of(context).readingRepository.createWeeklyReading(
            CreateWeeklyReadingRequest(
              kind: _kind,
              title: _title.text.trim(),
              source: _source.text.trim(),
              excerpt: _excerpt.text.trim(),
              imageUrl: _imageUrl.text.trim(),
              metaLabel: _kind.labelPt,
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
                          'Nova leitura',
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
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    children: [
                      SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<WeeklyReadingKind>(
                              value: _kind,
                              decoration: const InputDecoration(
                                labelText: 'Tipo',
                                prefixIcon: Icon(Icons.category_outlined),
                              ),
                              items: WeeklyReadingKind.values
                                  .map(
                                    (k) => DropdownMenuItem(
                                      value: k,
                                      child: Text(k.labelPt),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _submitting
                                  ? null
                                  : (v) => setState(
                                        () => _kind = v ?? _kind,
                                      ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _title,
                              decoration: const InputDecoration(
                                labelText: 'Título',
                                prefixIcon: Icon(Icons.title_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _source,
                              decoration: const InputDecoration(
                                labelText: 'Fonte',
                                hintText: 'Ex.: Veiga.dev',
                                prefixIcon: Icon(Icons.source_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _excerpt,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Resumo',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.notes_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _imageUrl,
                              decoration: const InputDecoration(
                                labelText: 'URL da imagem (opcional)',
                                prefixIcon: Icon(Icons.image_outlined),
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
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Publicar',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
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
