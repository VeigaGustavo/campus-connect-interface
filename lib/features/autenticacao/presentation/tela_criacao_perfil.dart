import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/rede/contratos_auth.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Criacao de perfil'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _typeSelector(),
                const SizedBox(height: 16),
                Text(
                  _titulo,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Preencha os dados para concluir seu cadastro.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 18),
                _field(_nomeCompleto, 'Nome completo'),
                const SizedBox(height: 10),
                _field(_idade, 'Idade', keyboard: TextInputType.number),
                const SizedBox(height: 10),
                _field(_cpf, 'CPF', keyboard: TextInputType.number),
                const SizedBox(height: 10),
                _field(_instituicao, 'Instituicao'),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: _field(_cidade, 'Cidade')),
                    const SizedBox(width: 10),
                    Expanded(child: _field(_estado, 'Estado (UF)')),
                  ],
                ),
                const SizedBox(height: 10),
                _field(_email, 'Email', keyboard: TextInputType.emailAddress),
                const SizedBox(height: 10),
                _field(_password, 'Senha', obscure: true),
                if (_type == RegisterProfileType.comunidade) ...[
                  const SizedBox(height: 10),
                  _field(_nomeComunidade, 'Nome da comunidade'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _tipoComunidade,
                    onChanged: (v) => setState(() => _tipoComunidade = v ?? 'atletica'),
                    decoration: _decoration('Tipo da comunidade'),
                    items: const [
                      DropdownMenuItem(value: 'atletica', child: Text('Atletica')),
                      DropdownMenuItem(value: 'ca', child: Text('CA')),
                    ],
                  ),
                ],
                if (_type == RegisterProfileType.empresa) ...[
                  const SizedBox(height: 10),
                  _field(_nomeEmpresa, 'Nome da empresa'),
                  const SizedBox(height: 10),
                  _field(_cnpjEmpresa, 'CNPJ (opcional)', required: false),
                  const SizedBox(height: 10),
                  _field(_descricaoEmpresa, 'Descricao da empresa (opcional)', required: false),
                ],
                if (_type == RegisterProfileType.universidade) ...[
                  const SizedBox(height: 10),
                  _field(_nomeInstituicao, 'Nome da instituicao'),
                  const SizedBox(height: 10),
                  _field(_siglaInstituicao, 'Sigla (opcional)', required: false),
                  const SizedBox(height: 10),
                  _field(_tipoInstituicao, 'Tipo (opcional)', required: false),
                  const SizedBox(height: 10),
                  _field(
                    _descricaoInstituicao,
                    'Descricao da instituicao (opcional)',
                    required: false,
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Criar perfil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _typeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _typeChip(RegisterProfileType.estudante, 'Estudante'),
        _typeChip(RegisterProfileType.comunidade, 'Admin comunidade'),
        _typeChip(RegisterProfileType.empresa, 'Empresa'),
        _typeChip(RegisterProfileType.universidade, 'Universidade'),
      ],
    );
  }

  Widget _typeChip(RegisterProfileType value, String label) {
    final selected = _type == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _type = value),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.chipBorder),
      backgroundColor: Colors.white,
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    bool required = true,
    bool obscure = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      obscureText: obscure,
      decoration: _decoration(label),
      validator: (v) {
        if (required && (v == null || v.trim().isEmpty)) {
          return 'Campo obrigatorio';
        }
        if (label == 'Email' && v != null && v.isNotEmpty && !v.contains('@')) {
          return 'Informe um email valido';
        }
        return null;
      },
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.chipBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.chipBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.2),
      ),
    );
  }
}
