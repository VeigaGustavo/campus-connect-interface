import 'package:campus_connect_interface/features/perfil/presentation/modal_configuracoes_perfil.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Rota legada: abre o mesmo conteúdo do modal e fecha ao sair.
class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final updated = await showProfileSettingsModal(context);
      if (mounted) context.pop(updated);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}
