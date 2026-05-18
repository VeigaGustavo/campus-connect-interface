import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';
import 'package:campus_connect_interface/features/grupos/domain/grupo_estudo.dart';
import 'package:campus_connect_interface/features/grupos/domain/painel_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/secao_detalhe_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/args_navegacao_grupo.dart';
import 'package:campus_connect_interface/features/grupos/presentation/widgets/painel_secao_grupo.dart';
import 'package:flutter/material.dart';

class GroupSectionScreen extends StatelessWidget {
  const GroupSectionScreen({
    super.key,
    required this.section,
    required this.group,
    required this.panel,
  });

  final GroupDetailSection section;
  final StudyGroup? group;
  final GroupContentPanel? panel;

  static GroupSectionScreen fromRouteExtra(Object? extra, String sectionName) {
    final section = GroupDetailSection.values.firstWhere(
      (s) => s.name == sectionName,
      orElse: () => GroupDetailSection.posts,
    );
    if (extra is GroupSectionRouteArgs) {
      return GroupSectionScreen(
        section: section,
        group: extra.group,
        panel: extra.panel,
      );
    }
    return GroupSectionScreen(section: section, group: null, panel: null);
  }

  @override
  Widget build(BuildContext context) {
    final p = panel;
    final List<FeedPostDetail> posts = p == null
        ? const []
        : switch (section) {
            GroupDetailSection.posts => p.postsFor(null),
            GroupDetailSection.articles => p.postsFor('article'),
            GroupDetailSection.notices => p.postsFor('notice'),
            GroupDetailSection.news => p.postsFor('campus_news'),
            GroupDetailSection.projects => p.postsFor('project'),
            GroupDetailSection.magazine => p.postsFor('magazine'),
            _ => const <FeedPostDetail>[],
          };

    return Scaffold(
      appBar: AppBar(
        title: Text(section.titlePt),
      ),
      body: GroupSectionPanel(
        section: section,
        loading: false,
        error: p == null ? 'Dados não carregados.' : null,
        posts: posts,
        events: p?.events ?? const [],
        memberCount: group?.memberCount ?? 0,
        chatAuthorIds: p?.chatMemberIds.toSet() ?? {},
        onRetry: () {},
      ),
    );
  }
}
