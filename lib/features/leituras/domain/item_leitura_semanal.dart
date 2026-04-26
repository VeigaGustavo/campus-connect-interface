enum WeeklyReadingKind {
  campusNews,
  magazine,
  article;

  String get labelPt => switch (this) {
        WeeklyReadingKind.campusNews => 'Notícia',
        WeeklyReadingKind.magazine => 'Revista',
        WeeklyReadingKind.article => 'Artigo',
      };
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
