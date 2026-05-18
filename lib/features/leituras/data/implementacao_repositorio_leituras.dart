import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';
import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/features/leituras/domain/repositorio_leituras.dart';
import 'package:campus_connect_interface/features/leituras/domain/item_leitura_semanal.dart';
import 'package:campus_connect_interface/features/leituras/domain/requisicao_criar_leitura.dart';

class ReadingRepositoryImpl implements ReadingRepository {
  ReadingRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<List<WeeklyReadingItem>> getWeeklyHighlights({
    WeeklyReadingKind? kind,
  }) async {
    final raw = await _api.get(
      '/api/reading/weekly',
      query: kind != null ? {'kind': kind.apiValue} : null,
      requiresAuth: true,
    );
    final list = decodeJsonListEnvelope(raw);
    return list
        .whereType<Map<String, dynamic>>()
        .map(_map)
        .toList(growable: false);
  }

  @override
  Future<WeeklyReadingItem> createWeeklyReading(
    CreateWeeklyReadingRequest request,
  ) async {
    final payload = WeeklyReadingPayload(
      kind: _readingKindPayload(request.kind),
      title: request.title,
      source: request.source,
      excerpt: request.excerpt,
      imageUrl: request.imageUrl,
      metaLabel: request.metaLabel.isNotEmpty
          ? request.metaLabel
          : request.kind.labelPt,
    );
    final raw = await _api.createWeeklyReading(payload);
    return _map(raw);
  }

  static ReadingKind _readingKindPayload(WeeklyReadingKind kind) =>
      switch (kind) {
        WeeklyReadingKind.campusNews => ReadingKind.campusNews,
        WeeklyReadingKind.magazine => ReadingKind.magazine,
        WeeklyReadingKind.article => ReadingKind.article,
      };

  static WeeklyReadingItem _map(Map<String, dynamic> j) {
    return WeeklyReadingItem(
      id: j['id']?.toString() ?? '',
      kind: WeeklyReadingKind.parseApi((j['kind'] ?? '').toString()),
      title: (j['title'] ?? '').toString(),
      source: (j['source'] ?? '').toString(),
      excerpt: (j['excerpt'] ?? '').toString(),
      imageUrl: (j['image_url'] ?? '').toString(),
      metaLabel: (j['meta_label'] ?? '').toString(),
    );
  }
}
