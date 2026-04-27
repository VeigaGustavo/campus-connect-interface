import 'package:campus_connect_interface/core/configuracao/configuracao_api.dart';
import 'package:campus_connect_interface/core/rede/cliente_http_log.dart';
import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';
import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/features/eventos/data/implementacao_repositorio_eventos.dart';
import 'package:campus_connect_interface/features/eventos/domain/repositorio_eventos.dart';
import 'package:campus_connect_interface/features/feed/data/implementacao_repositorio_feed_posts.dart';
import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';
import 'package:campus_connect_interface/features/grupos/data/implementacao_repositorio_grupos.dart';
import 'package:campus_connect_interface/features/grupos/domain/repositorio_grupos.dart';
import 'package:campus_connect_interface/features/inicio/data/implementacao_repositorio_feed_inicio.dart';
import 'package:campus_connect_interface/features/inicio/domain/repositorio_feed_inicio.dart';
import 'package:campus_connect_interface/features/oportunidades/data/implementacao_repositorio_oportunidades.dart';
import 'package:campus_connect_interface/features/oportunidades/domain/repositorio_oportunidades.dart';
import 'package:campus_connect_interface/features/perfil/data/implementacao_repositorio_perfil.dart';
import 'package:campus_connect_interface/features/perfil/domain/repositorio_perfil.dart';
import 'package:campus_connect_interface/features/leituras/data/implementacao_repositorio_leituras.dart';
import 'package:campus_connect_interface/features/leituras/domain/repositorio_leituras.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CampusDependencies {
  factory CampusDependencies({CampusApiClient? apiClient}) {
    final client = apiClient ??
        CampusApiClient(
          baseUrl: ApiConfig.baseUrl,
          httpClient: kDebugMode ? LoggingHttpClient(http.Client()) : null,
        );
    return CampusDependencies._(
      apiClient: client,
      currentUserRole: ApiConfig.debugUserRole,
      homeFeedRepository: HomeFeedRepositoryImpl(client),
      opportunitiesRepository: OpportunitiesRepositoryImpl(client),
      eventsRepository: EventsRepositoryImpl(client),
      groupsRepository: GroupsRepositoryImpl(client),
      feedPostsRepository: FeedPostsRepositoryImpl(client),
      profileRepository: ProfileRepositoryImpl(client),
      readingRepository: ReadingRepositoryImpl(client),
    );
  }

  const CampusDependencies._({
    required this.apiClient,
    required this.currentUserRole,
    required this.homeFeedRepository,
    required this.opportunitiesRepository,
    required this.eventsRepository,
    required this.groupsRepository,
    required this.feedPostsRepository,
    required this.profileRepository,
    required this.readingRepository,
  });

  final CampusApiClient apiClient;
  final AppUserRole currentUserRole;
  final HomeFeedRepository homeFeedRepository;
  final OpportunitiesRepository opportunitiesRepository;
  final EventsRepository eventsRepository;
  final GroupsRepository groupsRepository;
  final FeedPostsRepository feedPostsRepository;
  final ProfileRepository profileRepository;
  final ReadingRepository readingRepository;
}

class DependencyScope extends InheritedWidget {
  const DependencyScope({
    super.key,
    required this.deps,
    required super.child,
  });

  final CampusDependencies deps;

  static CampusDependencies of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<DependencyScope>();
    assert(scope != null, 'DependencyScope not found');
    return scope!.deps;
  }

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;
}
