import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/autenticacao/sessao_local.dart';
import 'package:campus_connect_interface/core/rede/excecao_api.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/core/widgets/mensagem_erro_api.dart';
import 'package:campus_connect_interface/features/perfil/domain/perfil_usuario.dart';
import 'package:campus_connect_interface/features/perfil/presentation/cartoes_secao_perfil.dart';
import 'package:campus_connect_interface/features/perfil/presentation/editor_lista_tags_perfil.dart';
import 'package:campus_connect_interface/features/perfil/presentation/secao_fotos_perfil.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Abre configurações do perfil como modal (ícone no cabeçalho).
/// Devolve `true` se o perfil foi alterado (fotos ou PUT).
Future<bool?> showProfileSettingsModal(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => const ProfileSettingsSheet(),
  );
}

class ProfileSettingsSheet extends StatefulWidget {
  const ProfileSettingsSheet({super.key});

  @override
  State<ProfileSettingsSheet> createState() => _ProfileSettingsSheetState();
}

class _ProfileSettingsSheetState extends State<ProfileSettingsSheet> {
  Future<_SheetData>? _future;
  bool _dirty = false;

  UserProfile? _profile;
  List<ProfileHistoryItem> _history = const [];

  final _aboutController = TextEditingController();
  final _institutionController = TextEditingController();
  final _courseController = TextEditingController();
  final _semesterController = TextEditingController();
  List<String> _interests = [];
  List<String> _favoriteTopics = [];
  List<String> _specialties = [];

  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  @override
  void dispose() {
    _aboutController.dispose();
    _institutionController.dispose();
    _courseController.dispose();
    _semesterController.dispose();
    super.dispose();
  }

  void _bindFromProfile(UserProfile p) {
    _profile = p;
    _aboutController.text = p.aboutMe;
    _institutionController.text = p.institutionName;
    _courseController.text = p.course;
    _semesterController.text = p.semester;
    _interests = List<String>.from(p.interests);
    _favoriteTopics = List<String>.from(p.favoriteTopics);
    _specialties = List<String>.from(p.specialties);
  }

  Future<_SheetData> _load() async {
    final repo = DependencyScope.of(context).profileRepository;
    final profile = await repo.getCurrentProfile();
    final history = await repo.getCurrentUserHistory(limit: 20);
    if (mounted) {
      setState(() {
        _bindFromProfile(profile);
        _history = history;
      });
    }
    return _SheetData(profile: profile, history: history);
  }

  Future<void> _reload() async {
    final next = _load();
    setState(() => _future = next);
    final data = await next;
    if (mounted) {
      _bindFromProfile(data.profile);
      _history = data.history;
    }
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _save() async {
    final p = _profile;
    if (p == null || _saving) return;

    setState(() => _saving = true);
    try {
      final repo = DependencyScope.of(context).profileRepository;
      final updated = await repo.updateCurrentProfile(
        ProfileUpdateInput(
          aboutMe: _aboutController.text.trim(),
          jobTitle: p.jobTitle,
          course: _courseController.text.trim(),
          semester: _semesterController.text.trim(),
          institutionName: _institutionController.text.trim(),
          mapUrl: p.organizationPanel?.mapUrl ?? '',
          interests: normalizeProfileTagList(_interests),
          favoriteTopics: normalizeProfileTagList(_favoriteTopics),
          specialties: normalizeProfileTagList(_specialties),
        ),
      );
      if (!mounted) return;
      _bindFromProfile(updated);
      setState(() {
        _dirty = false;
        _saving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível salvar (${e.statusCode}).'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await LocalSessionStore.clear();
    if (!mounted) return;
    DependencyScope.of(context).apiClient.clearAccessToken();
    if (mounted) context.go('/login');
  }

  void _close() {
    Navigator.of(context).pop(_dirty);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) {
          return Material(
            color: AppColors.background,
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
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _saving ? null : _close,
                        icon: const Icon(Icons.close_rounded),
                      ),
                      Expanded(
                        child: Text(
                          _profile?.profileType.settingsScreenTitle ??
                              'Configurações',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _saving || !_dirty ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Salvar',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: FutureBuilder<_SheetData>(
                    future: _future,
                    builder: (context, snap) {
                      if (_future == null ||
                          snap.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError) {
                        return ApiErrorPlaceholder(
                          message: snap.error.toString(),
                          onRetry: _reload,
                        );
                      }
                      final data = snap.data!;
                      final t = data.profile.profileType;
                      final repo =
                          DependencyScope.of(context).profileRepository;

                      return ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                        children: [
                          Text(
                            t.settingsIntroLine,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              color: AppColors.textSecondary.withValues(
                                alpha: 0.92,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ProfilePhotosSection(
                            repo: repo,
                            onPhotosChanged: () {
                              _markDirty();
                              _reload();
                            },
                          ),
                          const SizedBox(height: 14),
                          if (!data.profile.isOrganizationProfile) ...[
                            _EditableAcademicCard(
                              institutionController: _institutionController,
                              courseController: _courseController,
                              semesterController: _semesterController,
                              onChanged: _markDirty,
                            ),
                            const SizedBox(height: 14),
                          ],
                          _EditableAboutCard(
                            profileType: t,
                            aboutController: _aboutController,
                            institutionController: _institutionController,
                            showInstitution: data.profile.isOrganizationProfile &&
                                t == AccountProfileType.comunidade,
                            onChanged: _markDirty,
                          ),
                          const SizedBox(height: 14),
                          _EditablePreferencesCard(
                            profileType: t,
                            interests: _interests,
                            favoriteTopics: _favoriteTopics,
                            specialties: _specialties,
                            onInterestsChanged: (v) {
                              setState(() => _interests = v);
                              _markDirty();
                            },
                            onFavoriteTopicsChanged: (v) {
                              setState(() => _favoriteTopics = v);
                              _markDirty();
                            },
                            onSpecialtiesChanged: (v) {
                              setState(() => _specialties = v);
                              _markDirty();
                            },
                          ),
                          const SizedBox(height: 14),
                          ProfileActivityPanelCard(
                            history: _history,
                            profileType: t,
                          ),
                          const SizedBox(height: 20),
                          SoftCard(
                            padding: const EdgeInsets.all(16),
                            child: OutlinedButton.icon(
                              onPressed: _saving
                                  ? null
                                  : () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text('Sair da conta'),
                                          content: const Text(
                                            'Deseja encerrar sua sessão neste dispositivo?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Cancelar'),
                                            ),
                                            FilledButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Sair'),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) await _logout();
                                    },
                              icon: const Icon(Icons.logout_rounded, size: 20),
                              label: const Text('Sair da conta'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFB91C1C),
                                side: const BorderSide(color: Color(0xFFFECACA)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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

class _SheetData {
  const _SheetData({required this.profile, required this.history});

  final UserProfile profile;
  final List<ProfileHistoryItem> history;
}

class _EditableAcademicCard extends StatelessWidget {
  const _EditableAcademicCard({
    required this.institutionController,
    required this.courseController,
    required this.semesterController,
    required this.onChanged,
  });

  final TextEditingController institutionController;
  final TextEditingController courseController;
  final TextEditingController semesterController;
  final VoidCallback onChanged;

  static const _fieldFill = Color(0xFFF8FAFC);

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.school_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'Formação acadêmica',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Instituição, graduação e período exibidos no seu perfil.',
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 420;
              final fields = [
                _field(
                  controller: institutionController,
                  label: 'Instituição',
                  hint: 'Ex.: UniCat',
                  icon: Icons.account_balance_outlined,
                ),
                _field(
                  controller: courseController,
                  label: 'Graduação',
                  hint: 'Ex.: Ciência da Computação',
                  icon: Icons.school_outlined,
                ),
                _field(
                  controller: semesterController,
                  label: 'Período',
                  hint: 'Ex.: 5 ou 5º semestre',
                  icon: Icons.calendar_month_outlined,
                ),
              ];

              if (stacked) {
                return Column(
                  children: [
                    for (var i = 0; i < fields.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      fields[i],
                    ],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < fields.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: fields[i]),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: _fieldFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _EditableAboutCard extends StatelessWidget {
  const _EditableAboutCard({
    required this.profileType,
    required this.aboutController,
    required this.institutionController,
    required this.showInstitution,
    required this.onChanged,
  });

  final AccountProfileType profileType;
  final TextEditingController aboutController;
  final TextEditingController institutionController;
  final bool showInstitution;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary.withValues(alpha: 0.95),
              ),
              const SizedBox(width: 8),
              Text(
                profileType.aboutCardTitle,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: aboutController,
            onChanged: (_) => onChanged(),
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              labelText: profileType.isInstitution
                  ? 'Descrição'
                  : 'Sobre mim',
              alignLabelWithHint: true,
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          if (showInstitution) ...[
            const SizedBox(height: 12),
            TextField(
              controller: institutionController,
              onChanged: (_) => onChanged(),
              decoration: InputDecoration(
                labelText: profileType.isInstitution
                    ? 'Nome da instituição'
                    : 'Instituição',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EditablePreferencesCard extends StatelessWidget {
  const _EditablePreferencesCard({
    required this.profileType,
    required this.interests,
    required this.favoriteTopics,
    required this.specialties,
    required this.onInterestsChanged,
    required this.onFavoriteTopicsChanged,
    required this.onSpecialtiesChanged,
  });

  final AccountProfileType profileType;
  final List<String> interests;
  final List<String> favoriteTopics;
  final List<String> specialties;
  final ValueChanged<List<String>> onInterestsChanged;
  final ValueChanged<List<String>> onFavoriteTopicsChanged;
  final ValueChanged<List<String>> onSpecialtiesChanged;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              SizedBox(width: 8),
              Text(
                'Preferências',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            profileType.preferencesSubtitle,
            style: TextStyle(
              fontSize: 13,
              height: 1.35,
              color: AppColors.textSecondary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 14),
          ProfileTagListEditor(
            title: 'Interesses',
            items: interests,
            tint: AppColors.primary,
            onChanged: onInterestsChanged,
            inputHint: 'Ex.: Backend, Startups',
          ),
          const SizedBox(height: 18),
          ProfileTagListEditor(
            title: 'Topicos favoritos',
            items: favoriteTopics,
            tint: const Color(0xFF0EA5E9),
            onChanged: onFavoriteTopicsChanged,
            inputHint: 'Ex.: Arquitetura, APIs',
          ),
          const SizedBox(height: 18),
          ProfileTagListEditor(
            title: 'Especialidades',
            items: specialties,
            tint: const Color(0xFF059669),
            onChanged: onSpecialtiesChanged,
            inputHint: 'Ex.: Go, PostgreSQL',
          ),
        ],
      ),
    );
  }
}
