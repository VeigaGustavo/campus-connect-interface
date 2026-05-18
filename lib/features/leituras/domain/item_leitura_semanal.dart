enum WeeklyReadingKind {
  campusNews,
  magazine,
  article;

  String get labelPt => switch (this) {
        WeeklyReadingKind.campusNews => 'Notícia campus',
        WeeklyReadingKind.magazine => 'Revista',
        WeeklyReadingKind.article => 'Artigo',
      };

  String get apiValue => switch (this) {
        WeeklyReadingKind.campusNews => 'campus_news',
        WeeklyReadingKind.magazine => 'magazine',
        WeeklyReadingKind.article => 'article',
      };

  static WeeklyReadingKind parseApi(String raw) {
    final s = raw.trim().toLowerCase();
    return switch (s) {
      'campus_news' ||
      'noticia' ||
      'notícia' ||
      'noticias' ||
      'news' =>
        WeeklyReadingKind.campusNews,
      'magazine' || 'revista' || 'revistas' || 'magazines' =>
        WeeklyReadingKind.magazine,
      'article' || 'artigo' || 'artigos' || 'articles' =>
        WeeklyReadingKind.article,
      _ => throw FormatException('reading kind desconhecido: $raw'),
    };
  }
}

class WeeklyReadingItem {
  const WeeklyReadingItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.source,
    required this.excerpt,
    required this.imageUrl,
    required this.metaLabel,
  });

  final String id;
  final WeeklyReadingKind kind;
  final String title;
  final String source;
  final String excerpt;
  final String imageUrl;
  final String metaLabel;
}
