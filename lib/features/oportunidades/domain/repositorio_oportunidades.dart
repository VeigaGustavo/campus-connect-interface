import 'package:campus_connect_interface/features/oportunidades/domain/oportunidade.dart';
import 'package:campus_connect_interface/features/oportunidades/domain/requisicao_criar_vaga.dart';

abstract class OpportunitiesRepository {
  Future<List<Opportunity>> listOpportunities({String? query});
  Future<Opportunity?> getById(String id);
  Future<Opportunity> createOpportunity(CreateOpportunityRequest request);
}
