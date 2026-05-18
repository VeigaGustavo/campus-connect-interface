import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/features/inicio/domain/filtro_feed_inicio.dart';
import 'package:campus_connect_interface/features/inicio/domain/item_feed_inicio.dart';
import 'package:campus_connect_interface/features/inicio/domain/repositorio_feed_inicio.dart';
import 'package:campus_connect_interface/features/inicio/domain/tipo_item_feed_inicio.dart';

class HomeFeedRepositoryImpl implements HomeFeedRepository {
  HomeFeedRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<List<HomeFeedItem>> loadFeed(
    HomeFeedFilter filter, {
    List<String> groupIds = const [],
  }) async {
    final query = <String, String>{'filter': _filterQuery(filter)};
    if (groupIds.isNotEmpty) {
      query['group_ids'] = groupIds.join(',');
    }
    final raw = await _api.get('/api/feed', query: query);
    final list = decodeJsonListEnvelope(raw);
    return list.map((e) => _mapItem(e as Map<String, dynamic>)).toList();
  }

  static String _filterQuery(HomeFeedFilter f) => switch (f) {
        HomeFeedFilter.all => 'all',
        HomeFeedFilter.opportunities => 'internships',
        HomeFeedFilter.events => 'events',
        HomeFeedFilter.groups => 'groups',
        HomeFeedFilter.projects => 'projects',
        HomeFeedFilter.readings => 'readings',
        HomeFeedFilter.notices => 'notices',
      };

  static HomeFeedItem _mapItem(Map<String, dynamic> j) {
    return HomeFeedItem(
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

  static HomeFeedKind _parseKind(String s) => switch (s) {
        'post' => HomeFeedKind.post,
        'internship' => HomeFeedKind.opportunity,
        'opportunity' => HomeFeedKind.opportunity,
        'event' => HomeFeedKind.event,
        'study_group' => HomeFeedKind.studyGroup,
        'project' => HomeFeedKind.project,
        'reading' => HomeFeedKind.reading,
        'notice' => HomeFeedKind.notice,
        _ => throw FormatException('kind feed desconhecido: $s'),
      };
}
