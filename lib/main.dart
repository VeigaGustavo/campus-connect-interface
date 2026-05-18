import 'package:campus_connect_interface/app/roteador_aplicativo.dart';
import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/autenticacao/papel_sessao_usuario.dart';
import 'package:campus_connect_interface/core/theme/tema_aplicativo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final sessionRole = UserSessionRole();
  final deps = CampusDependencies(sessionRole: sessionRole);
  final router = createAppRouter(sessionRole: sessionRole, deps: deps);
  runApp(CampusConnectApp(router: router, deps: deps));
}

class CampusConnectApp extends StatefulWidget {
  const CampusConnectApp({
    super.key,
    required this.router,
    required this.deps,
  });

  final GoRouter router;
  final CampusDependencies deps;

  @override
  State<CampusConnectApp> createState() => _CampusConnectAppState();
}

class _CampusConnectAppState extends State<CampusConnectApp> {
  @override
  void initState() {
    super.initState();
    widget.deps.sessionRole.syncFromLocalSession();
    widget.deps.sessionRole.addListener(_onRoleChanged);
  }

  @override
  void dispose() {
    widget.deps.sessionRole.removeListener(_onRoleChanged);
    super.dispose();
  }

  void _onRoleChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return DependencyScope(
      deps: widget.deps,
      child: MaterialApp.router(
        title: 'CampusConnect',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: widget.router,
      ),
    );
  }
}
