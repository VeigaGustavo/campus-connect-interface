import 'package:campus_connect_interface/features/eventos/domain/evento_campus.dart';

abstract class EventsRepository {
  Future<List<CampusEvent>> listEvents();
}
