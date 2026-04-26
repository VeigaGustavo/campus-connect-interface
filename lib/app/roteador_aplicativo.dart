import 'package:campus_connect_interface/core/autenticacao/sessao_local.dart';
import 'package:campus_connect_interface/features/autenticacao/presentation/tela_login.dart';
import 'package:campus_connect_interface/features/autenticacao/presentation/tela_criacao_perfil.dart';
import 'package:campus_connect_interface/features/eventos/presentation/tela_lista_eventos.dart';
import 'package:campus_connect_interface/features/feed/presentation/tela_detalhe_post_feed.dart';
import 'package:campus_connect_interface/features/grupos/presentation/tela_grupos.dart';
import 'package:campus_connect_interface/features/inicio/presentation/tela_inicio.dart';
import 'package:campus_connect_interface/features/oportunidades/presentation/tela_detalhe_oportunidade.dart';
import 'package:campus_connect_interface/features/oportunidades/presentation/tela_oportunidades.dart';
import 'package:campus_connect_interface/features/perfil/presentation/tela_perfil.dart';
import 'package:campus_connect_interface/features/leituras/presentation/tela_leituras.dart';
import 'package:campus_connect_interface/features/painel_principal/painel_principal.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) async {
      final session = await LocalSessionStore.read();
      final isLoggedIn = session != null;
      final path = state.uri.path;
      final isAuthRoute = path == '/login' || path == '/signup';

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }
      if (isLoggedIn && isAuthRoute) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const ProfileCreationScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/opportunities',
                builder: (context, state) => const OpportunitiesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reading',
                builder: (context, state) => const ReadingScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/groups',
                builder: (context, state) => const GroupsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/opportunity/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OpportunityDetailScreen(opportunityId: id);
        },
      ),
      GoRoute(
        path: '/events',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) => const EventsListScreen(),
      ),
      GoRoute(
        path: '/feed/posts/:id',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return FeedPostDetailScreen(postId: id);
        },
      ),
    ],
  );
}
