import 'package:campus_connect_interface/features/leituras/domain/item_leitura_semanal.dart';
import 'package:campus_connect_interface/features/leituras/domain/requisicao_criar_leitura.dart';

abstract class ReadingRepository {
  Future<List<WeeklyReadingItem>> getWeeklyHighlights({
    WeeklyReadingKind? kind,
  });

  Future<WeeklyReadingItem> createWeeklyReading(CreateWeeklyReadingRequest request);
}
