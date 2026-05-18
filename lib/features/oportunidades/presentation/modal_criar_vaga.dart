import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/rede/excecao_api.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/campo_selecao_pesquisavel.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/core/widgets/snackbar_erro_api.dart';
import 'package:campus_connect_interface/features/oportunidades/domain/modalidade_trabalho.dart';
import 'package:campus_connect_interface/features/oportunidades/domain/tipos_vaga.dart';
import 'package:campus_connect_interface/features/oportunidades/domain/requisicao_criar_vaga.dart';
import 'package:campus_connect_interface/features/perfil/presentation/editor_lista_tags_perfil.dart';
import 'package:flutter/material.dart';

Future<bool?> showCreateOpportunityModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const CreateOpportunitySheet(),
  );
}

class CreateOpportunitySheet extends StatefulWidget {
  const CreateOpportunitySheet({super.key});

  @override
  State<CreateOpportunitySheet> createState() => _CreateOpportunitySheetState();
}

class _CreateOpportunitySheetState extends State<CreateOpportunitySheet> {
  final _title = TextEditingController();
  final _shortDescription = TextEditingController();
  final _fullDescription = TextEditingController();
  final _deadlineLabel = TextEditingController();
  String _typeLabel = '';
  DateTime? _applyDeadline;
  WorkLocation _workLocation = WorkLocation.hybrid;
  bool _submitting = false;
  bool _profileLoaded = false;
  bool _loadingProfile = true;
  String _companyName = '';
  List<String> _requirements = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCompanyFromProfile();
  }

  @override
  void dispose() {
    _title.dispose();
    _shortDescription.dispose();
    _fullDescription.dispose();
    _deadlineLabel.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyFromProfile() async {
    if (_profileLoaded) return;
    _profileLoaded = true;
    try {
      final profile =
          await DependencyScope.of(context).profileRepository.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _companyName = profile.name.trim();
        _loadingProfile = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  String _formatDateBr(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final m = d.month.toString().padLeft(2, '0');
    return '$day/$m/${d.year}';
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _applyDeadline ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: now,
      lastDate: DateTime(now.year + 2, 12, 31),
      helpText: 'Prazo para candidaturas',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (picked == null) return;
    setState(() {
      _applyDeadline = picked;
      _deadlineLabel.text = _formatDateBr(picked);
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final company = _companyName.trim();
    if (company.isEmpty) {
      showFloatingSnackBar(
        context,
        'Não foi possível obter o nome da empresa no perfil. '
        'Atualize seu perfil e tente novamente.',
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final repo = DependencyScope.of(context).opportunitiesRepository;
      await repo.createOpportunity(
        CreateOpportunityRequest(
          title: _title.text.trim(),
          companyName: company,
          shortDescription: _shortDescription.text.trim(),
          fullDescription: _fullDescription.text.trim(),
          applyDeadline:
              _applyDeadline ?? DateTime.now().add(const Duration(days: 30)),
          workLocation: _workLocation,
          typeLabel: _typeLabel.trim(),
          requirements: normalizeProfileTagList(_requirements),
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
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
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
                          'Nova vaga',
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
                            TextField(
                              controller: _title,
                              decoration: const InputDecoration(
                                labelText: 'Título da vaga',
                                prefixIcon: Icon(Icons.work_outline_rounded),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _CompanyFromProfileField(
                              companyName: _companyName,
                              loading: _loadingProfile,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _shortDescription,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Resumo',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.subject_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _fullDescription,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Descrição completa',
                                alignLabelWithHint: true,
                                prefixIcon: Icon(Icons.article_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SearchableSelectionField(
                              label: 'Tipo',
                              hintText: 'Buscar estágio, CLT, trainee…',
                              icon: Icons.label_outline_rounded,
                              options: OpportunityTypeLabels.all,
                              value: _typeLabel.isEmpty ? null : _typeLabel,
                              enabled: !_submitting,
                              onSelected: (v) =>
                                  setState(() => _typeLabel = v.trim()),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _deadlineLabel,
                              readOnly: true,
                              onTap: _submitting ? null : _pickDeadline,
                              decoration: InputDecoration(
                                labelText: 'Prazo de candidatura',
                                hintText: 'Toque para escolher',
                                prefixIcon: const Icon(Icons.event_outlined),
                                suffixIcon: IconButton(
                                  icon: const Icon(Icons.calendar_month_rounded),
                                  onPressed:
                                      _submitting ? null : _pickDeadline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<WorkLocation>(
                              value: _workLocation,
                              decoration: const InputDecoration(
                                labelText: 'Modalidade',
                                prefixIcon: Icon(Icons.place_outlined),
                              ),
                              items: WorkLocation.values
                                  .map(
                                    (w) => DropdownMenuItem(
                                      value: w,
                                      child: Text(w.labelPt),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _submitting
                                  ? null
                                  : (v) => setState(
                                        () => _workLocation =
                                            v ?? WorkLocation.hybrid,
                                      ),
                            ),
                            const SizedBox(height: 16),
                            ProfileTagListEditor(
                              title: 'Requisitos',
                              items: _requirements,
                              tint: const Color(0xFF059669),
                              inputHint: 'Ex.: Inglês intermediário, Git',
                              helpText:
                                  'Enter ou vírgula para adicionar cada requisito. Remova com o ×.',
                              onChanged: (v) =>
                                  setState(() => _requirements = v),
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
                            'Publicar vaga',
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

class _CompanyFromProfileField extends StatelessWidget {
  const _CompanyFromProfileField({
    required this.companyName,
    required this.loading,
  });

  final String companyName;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Nome da empresa',
        helperText: 'Do seu perfil',
        prefixIcon: Icon(Icons.apartment_outlined),
        filled: true,
        fillColor: Color(0xFFF8FAFC),
      ),
      child: loading
          ? const SizedBox(
              height: 20,
              child: Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          : Text(
              companyName.isNotEmpty ? companyName : '—',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: companyName.isNotEmpty
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
              ),
            ),
    );
  }
}
