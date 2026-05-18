import 'package:campus_connect_interface/core/widgets/barra_navegacao_inferior.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: CampusBottomNav(
        currentIndex: navigationShell.currentIndex,
        onBranchSelected: (i) => navigationShell.goBranch(i),
      ),
    );
  }
}
