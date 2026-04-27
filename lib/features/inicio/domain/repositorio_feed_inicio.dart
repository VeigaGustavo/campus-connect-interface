import 'package:campus_connect_interface/features/inicio/domain/filtro_feed_inicio.dart';
import 'package:campus_connect_interface/features/inicio/domain/item_feed_inicio.dart';

abstract class HomeFeedRepository {
  Future<List<HomeFeedItem>> loadFeed(
    HomeFeedFilter filter, {
    List<String> groupIds = const [],
  });
}
