enum GroupDetailSection {
  chat,
  posts,
  articles,
  notices,
  news,
  projects,
  magazine,
  events,
  members,
}

extension GroupDetailSectionX on GroupDetailSection {
  String get titlePt => switch (this) {
        GroupDetailSection.chat => 'Chat',
        GroupDetailSection.posts => 'Publicações',
        GroupDetailSection.articles => 'Artigos',
        GroupDetailSection.notices => 'Avisos',
        GroupDetailSection.news => 'Notícias',
        GroupDetailSection.projects => 'Projetos',
        GroupDetailSection.magazine => 'Revistas',
        GroupDetailSection.events => 'Eventos',
        GroupDetailSection.members => 'Participantes',
      };

  static GroupDetailSection? fromMenuId(String id) => switch (id) {
        'posts' => GroupDetailSection.posts,
        'articles' => GroupDetailSection.articles,
        'notices' => GroupDetailSection.notices,
        'news' => GroupDetailSection.news,
        'projects' => GroupDetailSection.projects,
        'magazine' => GroupDetailSection.magazine,
        'events' => GroupDetailSection.events,
        'members' => GroupDetailSection.members,
        _ => null,
      };
}
