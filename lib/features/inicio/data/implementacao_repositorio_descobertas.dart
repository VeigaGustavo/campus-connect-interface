import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/features/inicio/domain/filtro_descoberta.dart';
import 'package:campus_connect_interface/features/inicio/domain/item_descoberta.dart';
import 'package:campus_connect_interface/features/inicio/domain/tipo_item_descoberta.dart';
import 'package:campus_connect_interface/features/inicio/domain/repositorio_descobertas.dart';

class DiscoverRepositoryImpl implements DiscoverRepository {
  DiscoverRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<List<DiscoverItem>> getDiscoverFeed(
    DiscoverFilter filter, {
    List<String> groupIds = const [],
  }) async {
    final query = <String, String>{'filter': _filterQuery(filter)};
    if (groupIds.isNotEmpty) {
      query['group_ids'] = groupIds.join(',');
    }
    final raw = await _api.get('/api/feed', query: query);
    final list = decodeJsonList(raw);
    return list.map((e) => _mapItem(e as Map<String, dynamic>)).toList();
  }

  static String _filterQuery(DiscoverFilter f) => switch (f) {
        DiscoverFilter.all => 'all',
        DiscoverFilter.opportunities => 'internships',
        DiscoverFilter.events => 'events',
        DiscoverFilter.groups => 'groups',
        DiscoverFilter.projects => 'projects',
        DiscoverFilter.readings => 'readings',
        DiscoverFilter.notices => 'notices',
      };

  static DiscoverItem _mapItem(Map<String, dynamic> j) {
    return DiscoverItem(
      id: j['id'].toString(),
      kind: _parseKind(j['kind'] as String),
      title: j['title'] as String,
      subtitle: j['subtitle'] as String,
      excerpt: j['excerpt'] as String,
      metaPrimary: j['meta_primary'] as String,
      metaSecondary: j['meta_secondary'] as String,
      referenceId: j['reference_id'].toString(),
      publishScope: (j['publish_scope'] ?? 'all').toString(),
      publishGroupId: j['publish_group_id']?.toString(),
    );
  }

  static DiscoverKind _parseKind(String s) => switch (s) {
        'internship' => DiscoverKind.opportunity,
        'opportunity' => DiscoverKind.opportunity,
        'event' => DiscoverKind.event,
        'study_group' => DiscoverKind.studyGroup,
        'project' => DiscoverKind.project,
        'reading' => DiscoverKind.reading,
        'notice' => DiscoverKind.notice,
        _ => throw FormatException('kind feed desconhecido: $s'),
      };
}
