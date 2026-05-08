import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/rede/contratos_auth.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/autenticacao/data/repositorio_autenticacao_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({super.key});

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();

  RegisterProfileType _type = RegisterProfileType.estudante;

  final _nomeCompleto = TextEditingController();
  final _idade = TextEditingController();
  final _cpf = TextEditingController();
  final _instituicao = TextEditingController();
  final _cidade = TextEditingController();
  final _estado = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  final _nomeComunidade = TextEditingController();
  String _tipoComunidade = 'atletica';

  final _nomeEmpresa = TextEditingController();
  final _cnpjEmpresa = TextEditingController();
  final _descricaoEmpresa = TextEditingController();
  final _nomeInstituicao = TextEditingController();
  final _siglaInstituicao = TextEditingController();
  final _tipoInstituicao = TextEditingController();
  final _descricaoInstituicao = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nomeCompleto.dispose();
    _idade.dispose();
    _cpf.dispose();
    _instituicao.dispose();
    _cidade.dispose();
    _estado.dispose();
    _email.dispose();
    _password.dispose();
    _nomeComunidade.dispose();
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final deps = DependencyScope.of(context);
    final repo = ApiAuthRepository(deps.apiClient);
    final dto = RegisterRequestDto(
      profileType: _type,
      fullName: _nomeCompleto.text.trim(),
      age: int.tryParse(_idade.text.trim()) ?? 0,
      cpf: _cpf.text.trim(),
      institution: _instituicao.text.trim(),
      city: _cidade.text.trim(),
      state: _estado.text.trim(),
      email: _email.text.trim(),
      password: _password.text.trim(),
      communityType: _type == RegisterProfileType.comunidade ? _tipoComunidade : null,
      communityName: _type == RegisterProfileType.comunidade
          ? _nomeComunidade.text.trim()
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil criado com sucesso.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/login');
    } on AuthActionError catch (e) {
      if (!mounted) return;
      final message = switch (e.type) {
        AuthActionErrorType.forbidden =>
          'Seu perfil nao pode executar esta acao.',
        AuthActionErrorType.unauthorized =>
          'Sessao invalida. Faça login novamente.',
        AuthActionErrorType.generic =>
          'Nao foi possivel criar o perfil. Tente novamente.',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
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
                        child: Form(
                          key: _formKey,
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
                                'Preencha os dados para concluir seu cadastro.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _field(
                                _nomeCompleto,
                                'Nome completo',
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 12),
                              _field(
                                _idade,
                                'Idade',
                                keyboard: TextInputType.number,
                                icon: Icons.cake_outlined,
                              ),
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
                                'Instituição',
                                icon: Icons.school_outlined,
                              ),
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
                              TextFormField(
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
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Campo obrigatorio';
                                  }
                                  return null;
                                },
                              ),
                              if (_type == RegisterProfileType.comunidade) ...[
                                const SizedBox(height: 12),
                                _field(
                                  _nomeComunidade,
                                  'Nome da comunidade',
                                  icon: Icons.diversity_3_outlined,
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  initialValue: _tipoComunidade,
                                  onChanged: (v) => setState(
                                    () => _tipoComunidade = v ?? 'atletica',
                                  ),
                                  decoration: _decoration(
                                    'Tipo da comunidade',
                                    icon: Icons.category_outlined,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'atletica',
                                      child: Text('Atlética'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'ca',
                                      child: Text('Centro Acadêmico'),
                                    ),
                                  ],
                                ),
                              ],
                              if (_type == RegisterProfileType.empresa) ...[
                                const SizedBox(height: 12),
                                _field(
                                  _nomeEmpresa,
                                  'Nome da empresa',
                                  icon: Icons.apartment_outlined,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  _cnpjEmpresa,
                                  'CNPJ (opcional)',
                                  required: false,
                                  icon: Icons.numbers_rounded,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  _descricaoEmpresa,
                                  'Descrição da empresa (opcional)',
                                  required: false,
                                  icon: Icons.description_outlined,
                                ),
                              ],
                              if (_type == RegisterProfileType.universidade) ...[
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
                                  required: false,
                                  icon: Icons.abc_outlined,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  _tipoInstituicao,
                                  'Tipo (opcional)',
                                  required: false,
                                  icon: Icons.label_outline_rounded,
                                ),
                                const SizedBox(height: 12),
                                _field(
                                  _descricaoInstituicao,
                                  'Descrição da instituição (opcional)',
                                  required: false,
                                  icon: Icons.article_outlined,
                                ),
                              ],
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
    bool required = true,
    bool obscure = false,
    IconData? icon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: _decoration(label, icon: icon),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return 'Campo obrigatorio';
        }
        if (label.startsWith('E-mail') &&
            v != null &&
            v.isNotEmpty &&
            !v.contains('@')) {
          return 'Informe um email valido';
        }
        return null;
      },
    );
  }

  InputDecoration _decoration(String label, {IconData? icon}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
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
