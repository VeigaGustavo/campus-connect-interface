enum DiscoverFilter {
  all,
  opportunities,
  events,
  groups,
  projects,
  readings,
  notices,
  posts,
}

extension DiscoverFilterX on DiscoverFilter {
  String get label => switch (this) {
    DiscoverFilter.all => 'Todos',
    DiscoverFilter.opportunities => 'Vagas',
    DiscoverFilter.events => 'Eventos',
    DiscoverFilter.groups => 'Grupos',
    DiscoverFilter.projects => 'Projetos',
    DiscoverFilter.readings => 'Leituras',
    DiscoverFilter.notices => 'Avisos',
    DiscoverFilter.posts => 'Posts',
  };
}
