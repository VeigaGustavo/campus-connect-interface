import 'package:campus_connect_interface/features/oportunidades/domain/oportunidade.dart';

abstract class OpportunitiesRepository {
  Future<List<Opportunity>> listOpportunities({String? query});
  Future<Opportunity?> getById(String id);
}
