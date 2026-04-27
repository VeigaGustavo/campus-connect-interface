import 'package:campus_connect_interface/core/rede/excecao_api.dart';
import 'package:campus_connect_interface/core/rede/cliente_http_campus.dart';
import 'package:campus_connect_interface/core/rede/decodificacao_json.dart';
import 'package:campus_connect_interface/features/oportunidades/domain/repositorio_oportunidades.dart';
import 'package:campus_connect_interface/features/oportunidades/domain/oportunidade.dart';
import 'package:campus_connect_interface/features/oportunidades/domain/modalidade_trabalho.dart';

class OpportunitiesRepositoryImpl implements OpportunitiesRepository {
  OpportunitiesRepositoryImpl(this._api);

  final CampusApiClient _api;

  @override
  Future<List<Opportunity>> listOpportunities({String? query}) async {
    final raw = await _api.get('/api/opportunities');
    final list = decodeJsonListEnvelope(raw);
    var mapped =
        list.map((e) => _mapOpportunity(e as Map<String, dynamic>)).toList();
    final q = query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      mapped = mapped
          .where(
            (o) =>
                o.title.toLowerCase().contains(q) ||
                o.companyName.toLowerCase().contains(q),
          )
          .toList();
    }
    return mapped;
  }

  @override
  Future<Opportunity?> getById(String id) async {
    try {
      final raw = await _api.get('/api/opportunities/$id');
      if (raw == null) return null;
      return _mapOpportunity(decodeJsonObject(raw));
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

  static Opportunity _mapOpportunity(Map<String, dynamic> j) {
    final reqs = j['requirements'];
    final reqList = reqs is List
        ? reqs.map((e) => e.toString()).toList()
        : <String>[];
    return Opportunity(
      id: j['id'].toString(),
      title: j['title'] as String,
      companyName: j['company_name'] as String,
      shortDescription: j['short_description'] as String,
      fullDescription: j['full_description'] as String,
      applyDeadline: DateTime.parse(j['apply_deadline'] as String),
      workLocation: _parseWorkLocation(j['work_location'] as String),
      typeLabel: j['type_label'] as String,
      requirements: reqList,
    );
  }

  static WorkLocation _parseWorkLocation(String s) => switch (s) {
        'remote' => WorkLocation.remote,
        'hybrid' => WorkLocation.hybrid,
        'on_site' => WorkLocation.onSite,
        _ => throw FormatException('work_location desconhecido: $s'),
      };
}
