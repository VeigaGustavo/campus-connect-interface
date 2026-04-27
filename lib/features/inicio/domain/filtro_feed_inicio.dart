enum HomeFeedFilter {
  all,
  opportunities,
  events,
  groups,
  projects,
  readings,
  notices,
}

extension HomeFeedFilterLabels on HomeFeedFilter {
  String get label => switch (this) {
        HomeFeedFilter.all => 'Todos',
        HomeFeedFilter.opportunities => 'Vagas',
        HomeFeedFilter.events => 'Eventos',
        HomeFeedFilter.groups => 'Grupos',
        HomeFeedFilter.projects => 'Projetos',
        HomeFeedFilter.readings => 'Leituras',
        HomeFeedFilter.notices => 'Avisos',
      };
}
