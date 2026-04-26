import 'package:campus_connect_interface/app/roteador_aplicativo.dart';
import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/theme/tema_aplicativo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final router = createAppRouter();
  runApp(CampusConnectApp(router: router));
}

class CampusConnectApp extends StatelessWidget {
  const CampusConnectApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return DependencyScope(
      deps: CampusDependencies(),
      child: MaterialApp.router(
        title: 'CampusConnect',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        routerConfig: router,
      ),
    );
  }
}
