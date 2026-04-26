import 'package:campus_connect_interface/features/leituras/domain/item_leitura_semanal.dart';

abstract class ReadingRepository {
  Future<List<WeeklyReadingItem>> getWeeklyHighlights();
}
