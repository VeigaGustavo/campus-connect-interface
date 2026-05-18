import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/rede/contratos_auth.dart';
import 'package:campus_connect_interface/core/rede/excecao_api.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/core/widgets/snackbar_erro_api.dart';
import 'package:campus_connect_interface/features/autenticacao/data/repositorio_autenticacao_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  RegisterProfileType _type = RegisterProfileType.estudante;

  final _nomeCompleto = TextEditingController();
  final _birthDateLabel = TextEditingController();
  DateTime? _birthDate;
  final _cpf = TextEditingController();
  final _instituicao = TextEditingController();
  final _cidade = TextEditingController();
  final _estado = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();

  final _nomeComunidade = TextEditingController();
  final _descricaoComunidade = TextEditingController();
  String _tipoComunidade = 'atletica';
  String _visibilidadeGrupo = 'public';

  final _nomeEmpresa = TextEditingController();
  final _cnpjEmpresa = TextEditingController();
  final _descricaoEmpresa = TextEditingController();
  final _nomeInstituicao = TextEditingController();
  final _siglaInstituicao = TextEditingController();
  final _tipoInstituicao = TextEditingController();
  final _descricaoInstituicao = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;

  @override
  void dispose() {
    _nomeCompleto.dispose();
    _birthDateLabel.dispose();
    _cpf.dispose();
    _instituicao.dispose();
    _cidade.dispose();
    _estado.dispose();
    _email.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    _nomeComunidade.dispose();
    _descricaoComunidade.dispose();
    _nomeEmpresa.dispose();
    _cnpjEmpresa.dispose();
    _descricaoEmpresa.dispose();
    _nomeInstituicao.dispose();
    _siglaInstituicao.dispose();
    _tipoInstituicao.dispose();
    _descricaoInstituicao.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final deps = DependencyScope.of(context);
    final repo = ApiAuthRepository(deps.apiClient);
    final institution = switch (_type) {
      RegisterProfileType.estudante => _instituicao.text.trim(),
      RegisterProfileType.comunidade => _instituicao.text.trim(),
      RegisterProfileType.universidade => _nomeInstituicao.text.trim(),
      RegisterProfileType.empresa => '',
    };
    final dto = RegisterRequestDto(
      profileType: _type,
      fullName: _nomeCompleto.text.trim(),
      birthDate: _birthDate,
      cpf: _cpf.text.trim(),
      institution: institution,
      city: _cidade.text.trim(),
      state: _estado.text.trim(),
      email: _email.text.trim(),
      password: _password.text.trim(),
      communityType: _type == RegisterProfileType.comunidade ? _tipoComunidade : null,
      communityName: _type == RegisterProfileType.comunidade
          ? _nomeComunidade.text.trim()
          : null,
      groupDescription: _type == RegisterProfileType.comunidade
          ? _descricaoComunidade.text.trim()
          : null,
      groupVisibility: _type == RegisterProfileType.comunidade
          ? _visibilidadeGrupo
          : null,
      companyName: _type == RegisterProfileType.empresa
          ? _nomeEmpresa.text.trim()
          : null,
      companyCnpj: _type == RegisterProfileType.empresa
          ? _cnpjEmpresa.text.trim()
          : null,
      companyDescription: _type == RegisterProfileType.empresa
          ? _descricaoEmpresa.text.trim()
          : null,
      institutionName: _type == RegisterProfileType.universidade
          ? _nomeInstituicao.text.trim()
          : null,
      institutionAcronym: _type == RegisterProfileType.universidade
          ? _siglaInstituicao.text.trim()
          : null,
      institutionType: _type == RegisterProfileType.universidade
          ? _tipoInstituicao.text.trim()
          : null,
      institutionDescription: _type == RegisterProfileType.universidade
          ? _descricaoInstituicao.text.trim()
          : null,
    );
    setState(() => _loading = true);
    try {
      await repo.register(dto);
      if (!mounted) return;
      showFloatingSnackBar(context, 'Perfil criado com sucesso.');
      context.go('/login');
    } on ApiException catch (e) {
      if (!mounted) return;
      showApiErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _titulo => switch (_type) {
        RegisterProfileType.estudante => 'Criar perfil de estudante',
        RegisterProfileType.comunidade => 'Criar perfil de admin da comunidade',
        RegisterProfileType.empresa => 'Criar perfil de empresa',
        RegisterProfileType.universidade => 'Criar perfil de universidade',
      };

  String get _instrucao => switch (_type) {
        RegisterProfileType.estudante =>
          'Preencha seus dados acadêmicos e de acesso.',
        RegisterProfileType.comunidade =>
          'Cadastre a comunidade, a instituição vinculada e o administrador.',
        RegisterProfileType.empresa =>
          'Cadastre a empresa e o responsável pela conta.',
        RegisterProfileType.universidade =>
          'Cadastre a instituição de ensino e o administrador.',
      };

  String _formatDateBr(DateTime d) {
    final day = d.day.toString().padLeft(2, '0');
    final m = d.month.toString().padLeft(2, '0');
    return '$day/$m/${d.year}';
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final last = DateTime(now.year, now.month, now.day);
    final first = DateTime(now.year - 120, 1, 1);
    final initial = _birthDate ?? DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first)
          ? first
          : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      helpText: 'Selecione a data de nascimento',
      cancelText: 'Cancelar',
      confirmText: 'OK',
    );
    if (picked == null) return;
    setState(() {
      _birthDate = picked;
      _birthDateLabel.text = _formatDateBr(picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/login'),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AppColors.textPrimary,
                      style: IconButton.styleFrom(
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Criar conta',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.primary.withValues(alpha: 0.12),
                              AppColors.secondary.withValues(alpha: 0.08),
                              AppColors.background,
                            ],
                            stops: const [0, 0.45, 1],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                          child: Column(
                            children: [
                              const Image(
                                image: AssetImage(
                                  'assets/images/campus_connect_logo.png',
                                ),
                                height: 96,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Junte-se ao CampusConnect',
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Um cadastro para vagas, eventos, leituras e grupos do campus.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SoftCard(
                        padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.workspace_premium_outlined,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tipo de perfil',
                                          style: textTheme.labelLarge?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.textSecondary,
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Escolha quem está se cadastrando.',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: AppColors.textSecondary
                                                .withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _typeSelector(),
                              const SizedBox(height: 22),
                              Divider(
                                height: 1,
                                color: AppColors.chipBorder
                                    .withValues(alpha: 0.85),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                _titulo,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _instrucao,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ..._buildProfileTypeFields(),
                              _sectionTitle('Localização e acesso'),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: _field(
                                      _cidade,
                                      'Cidade',
                                      icon: Icons.location_city_outlined,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _field(
                                      _estado,
                                      'Estado (UF)',
                                      icon: Icons.map_outlined,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _field(
                                _email,
                                'E-mail',
                                keyboard: TextInputType.emailAddress,
                                icon: Icons.alternate_email_rounded,
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _password,
                                obscureText: _obscurePassword,
                                decoration: _decoration(
                                  'Senha',
                                  icon: Icons.key_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Mostrar senha'
                                        : 'Ocultar senha',
                                    onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword,
                                    ),
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _passwordConfirm,
                                obscureText: _obscurePasswordConfirm,
                                decoration: _decoration(
                                  'Confirmar senha',
                                  icon: Icons.verified_user_outlined,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePasswordConfirm
                                        ? 'Mostrar senha'
                                        : 'Ocultar senha',
                                    onPressed: () => setState(
                                      () => _obscurePasswordConfirm =
                                          !_obscurePasswordConfirm,
                                    ),
                                    icon: Icon(
                                      _obscurePasswordConfirm
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              FilledButton(
                                onPressed: _loading ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _loading
                                    ? SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.onPrimary,
                                        ),
                                      )
                                    : const Text(
                                        'Criar perfil',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 20),
                              Text.rich(
                                TextSpan(
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Já tem uma conta? '),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.baseline,
                                      baseline: TextBaseline.alphabetic,
                                      child: TextButton(
                                        onPressed: () => context.go('/login'),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Entrar',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Ao criar sua conta, você concorda com os termos e a política de privacidade.',
                                textAlign: TextAlign.center,
                                style: textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant
                                      .withValues(alpha: 0.85),
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProfileTypeFields() {
    return switch (_type) {
      RegisterProfileType.estudante => _buildStudentFields(),
      RegisterProfileType.comunidade => [
          ..._buildComunidadeFields(),
          const SizedBox(height: 20),
          ..._buildAdminFields(),
        ],
      RegisterProfileType.empresa => [
          ..._buildEmpresaFields(),
          const SizedBox(height: 20),
          ..._buildAdminFields(),
        ],
      RegisterProfileType.universidade => [
          ..._buildUniversidadeFields(),
          const SizedBox(height: 20),
          ..._buildAdminFields(),
        ],
    };
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }

  List<Widget> _buildStudentFields() => [
        _field(
          _nomeCompleto,
          'Nome completo',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),
        _buildBirthDateField(),
        const SizedBox(height: 12),
        _field(
          _cpf,
          'CPF',
          keyboard: TextInputType.number,
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 12),
        _field(
          _instituicao,
          'Instituição de ensino',
          icon: Icons.school_outlined,
        ),
        const SizedBox(height: 20),
      ];

  List<Widget> _buildAdminFields() => [
        _sectionTitle(
          _type == RegisterProfileType.comunidade
              ? 'Administrador da comunidade'
              : 'Responsável pela conta',
        ),
        const SizedBox(height: 12),
        _field(
          _nomeCompleto,
          'Nome completo',
          icon: Icons.person_outline_rounded,
        ),
        const SizedBox(height: 12),
        _buildBirthDateField(),
        const SizedBox(height: 12),
        _field(
          _cpf,
          'CPF',
          keyboard: TextInputType.number,
          icon: Icons.badge_outlined,
        ),
        const SizedBox(height: 20),
      ];

  Widget _buildBirthDateField() {
    return TextField(
      controller: _birthDateLabel,
      readOnly: true,
      onTap: () {
        FocusScope.of(context).unfocus();
        _pickBirthDate();
      },
      decoration: _decoration(
        'Data de nascimento',
        icon: Icons.calendar_month_outlined,
      ).copyWith(
        hintText: 'Toque para escolher',
        suffixIcon: IconButton(
          icon: const Icon(Icons.event_rounded),
          color: AppColors.primary,
          onPressed: () {
            FocusScope.of(context).unfocus();
            _pickBirthDate();
          },
          tooltip: 'Escolher data',
        ),
      ),
    );
  }

  List<Widget> _buildComunidadeFields() => [
        _sectionTitle('Comunidade'),
        const SizedBox(height: 12),
        _field(
          _nomeComunidade,
          'Nome da comunidade',
          icon: Icons.diversity_3_outlined,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _tipoComunidade,
          onChanged: (v) => setState(() => _tipoComunidade = v ?? 'atletica'),
          decoration: _decoration(
            'Tipo da comunidade',
            icon: Icons.category_outlined,
          ),
          items: const [
            DropdownMenuItem(value: 'atletica', child: Text('Atlética')),
            DropdownMenuItem(
              value: 'ca',
              child: Text('Centro Acadêmico'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _field(
          _descricaoComunidade,
          'Descrição da comunidade',
          maxLines: 3,
          icon: Icons.notes_outlined,
        ),
        const SizedBox(height: 12),
        _field(
          _instituicao,
          'Instituição vinculada',
          icon: Icons.apartment_outlined,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'O grupo principal é criado automaticamente com este cadastro.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Visibilidade do grupo',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
          selected: {_visibilidadeGrupo},
          onSelectionChanged: (s) =>
              setState(() => _visibilidadeGrupo = s.first),
        ),
        const SizedBox(height: 4),
        Text(
          _visibilidadeGrupo == 'public'
              ? 'Qualquer pessoa pode entrar direto.'
              : 'Novos membros precisam de aprovação.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 20),
      ];

  List<Widget> _buildEmpresaFields() => [
        _sectionTitle('Empresa'),
        const SizedBox(height: 12),
        _field(
          _nomeEmpresa,
          'Nome da empresa',
          icon: Icons.business_outlined,
        ),
        const SizedBox(height: 12),
        _field(
          _cnpjEmpresa,
          'CNPJ (opcional)',
          icon: Icons.numbers_rounded,
        ),
        const SizedBox(height: 12),
        _field(
          _descricaoEmpresa,
          'Descrição da empresa (opcional)',
          maxLines: 3,
          icon: Icons.description_outlined,
        ),
        const SizedBox(height: 20),
      ];

  List<Widget> _buildUniversidadeFields() => [
        _sectionTitle('Instituição de ensino'),
        const SizedBox(height: 12),
        _field(
          _nomeInstituicao,
          'Nome da instituição',
          icon: Icons.account_balance_outlined,
        ),
        const SizedBox(height: 12),
        _field(
          _siglaInstituicao,
          'Sigla (opcional)',
          icon: Icons.abc_outlined,
        ),
        const SizedBox(height: 12),
        _field(
          _tipoInstituicao,
          'Tipo (opcional)',
          hint: 'Ex.: federal, estadual',
          icon: Icons.label_outline_rounded,
        ),
        const SizedBox(height: 12),
        _field(
          _descricaoInstituicao,
          'Descrição (opcional)',
          maxLines: 3,
          icon: Icons.article_outlined,
        ),
        const SizedBox(height: 20),
      ];

  Widget _typeSelector() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 420;
        if (wide) {
          return Row(
            children: [
              Expanded(
                child: _typeTile(
                  RegisterProfileType.estudante,
                  'Estudante',
                  Icons.school_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _typeTile(
                  RegisterProfileType.comunidade,
                  'Comunidade',
                  Icons.groups_2_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _typeTile(
                  RegisterProfileType.empresa,
                  'Empresa',
                  Icons.business_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _typeTile(
                  RegisterProfileType.universidade,
                  'Universidade',
                  Icons.account_balance_outlined,
                ),
              ),
            ],
          );
        }
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _typeTile(
              RegisterProfileType.estudante,
              'Estudante',
              Icons.school_outlined,
            ),
            _typeTile(
              RegisterProfileType.comunidade,
              'Admin comunidade',
              Icons.groups_2_outlined,
            ),
            _typeTile(
              RegisterProfileType.empresa,
              'Empresa',
              Icons.business_outlined,
            ),
            _typeTile(
              RegisterProfileType.universidade,
              'Universidade',
              Icons.account_balance_outlined,
            ),
          ],
        );
      },
    );
  }

  Widget _typeTile(
    RegisterProfileType value,
    String label,
    IconData icon,
  ) {
    final selected = _type == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _type = value),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.chipBorder,
              width: selected ? 1.4 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: selected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    bool obscure = false,
    IconData? icon,
    String? hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      maxLines: maxLines,
      decoration: _decoration(label, icon: icon, hint: hint),
    );
  }

  InputDecoration _decoration(String label, {IconData? icon, String? hint}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      filled: true,
      fillColor: AppColors.background.withValues(alpha: 0.65),
      prefixIcon: icon != null
          ? Icon(icon, color: scheme.onSurfaceVariant, size: 22)
          : null,
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.error.withValues(alpha: 0.85)),
      ),
    );
  }
}
