import 'package:campus_connect_interface/features/inicio/domain/filtro_descoberta.dart';
import 'package:campus_connect_interface/features/inicio/domain/item_descoberta.dart';

abstract class DiscoverRepository {
  Future<List<DiscoverItem>> getDiscoverFeed(
    DiscoverFilter filter, {
    List<String> groupIds = const [],
  });
}
