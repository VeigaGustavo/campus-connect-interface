import 'package:campus_connect_interface/features/leituras/domain/item_leitura_semanal.dart';

class CreateWeeklyReadingRequest {
  const CreateWeeklyReadingRequest({
    required this.kind,
    required this.title,
    required this.source,
    required this.excerpt,
    this.imageUrl = '',
    this.metaLabel = '',
  });

  final WeeklyReadingKind kind;
  final String title;
  final String source;
  final String excerpt;
  final String imageUrl;
  final String metaLabel;
}
