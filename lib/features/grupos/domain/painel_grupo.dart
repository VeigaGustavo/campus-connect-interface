import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';

class GroupContentPanel {
  const GroupContentPanel({
    required this.allPosts,
    required this.events,
    required this.chatMemberIds,
  });

  final List<FeedPostDetail> allPosts;
  final List<Map<String, dynamic>> events;
  final List<String> chatMemberIds;

  int get postsTotal => allPosts.length;

  int get articlesTotal =>
      allPosts.where((p) => p.contentKind == 'article').length;

  int get noticesTotal =>
      allPosts.where((p) => p.contentKind == 'notice').length;

  int get newsTotal =>
      allPosts.where((p) => p.contentKind == 'campus_news').length;

  int get projectsTotal =>
      allPosts.where((p) => p.contentKind == 'project').length;

  int get magazineTotal =>
      allPosts.where((p) => p.contentKind == 'magazine').length;

  int get eventsTotal => events.length;

  List<FeedPostDetail> postsFor(String? contentKind) {
    if (contentKind == null) return allPosts;
    return allPosts.where((p) => p.contentKind == contentKind).toList();
  }
}

class GroupPanelListItem {
  const GroupPanelListItem({
    required this.id,
    required this.title,
    this.subtitle = '',
  });

  final String id;
  final String title;
  final String subtitle;
}
