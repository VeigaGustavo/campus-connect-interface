import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/features/leituras/domain/repositorio_leituras.dart';
import 'package:campus_connect_interface/features/leituras/domain/item_leitura_semanal.dart';

class ReadingRepositoryImpl implements ReadingRepository {
  ReadingRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<List<WeeklyReadingItem>> getWeeklyHighlights() async {
    final raw = await _api.get('/api/reading/weekly');
    final list = decodeJsonListEnvelope(raw);
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  static WeeklyReadingItem _map(Map<String, dynamic> j) {
    return WeeklyReadingItem(
      id: j['id'].toString(),
      kind: _parseKind(j['kind'] as String),
      title: j['title'] as String,
      source: j['source'] as String,
      excerpt: j['excerpt'] as String,
      imageUrl: j['image_url'] as String,
      metaLabel: j['meta_label'] as String,
    );
  }

  static WeeklyReadingKind _parseKind(String s) => switch (s) {
        'campus_news' => WeeklyReadingKind.campusNews,
        'magazine' => WeeklyReadingKind.magazine,
        'article' => WeeklyReadingKind.article,
        _ => throw FormatException('reading kind desconhecido: $s'),
      };
}
