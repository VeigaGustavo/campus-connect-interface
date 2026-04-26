import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/features/eventos/domain/evento_campus.dart';
import 'package:campus_connect_interface/features/eventos/domain/repositorio_eventos.dart';

class EventsRepositoryImpl implements EventsRepository {
  EventsRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<List<CampusEvent>> listEvents() async {
    final raw = await _api.get('/api/events');
    final list = decodeJsonList(raw);
    return list.map((e) => _map(e as Map<String, dynamic>)).toList();
  }

  static CampusEvent _map(Map<String, dynamic> j) {
    return CampusEvent(
      id: j['id'].toString(),
      title: j['title'] as String,
      description: j['description'] as String,
      startAt: DateTime.parse(j['start_at'] as String),
      location: j['location'] as String,
      organizer: j['organizer'] as String,
    );
  }
}
