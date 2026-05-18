import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/core/widgets/mensagem_erro_api.dart';
import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';
import 'package:campus_connect_interface/features/grupos/domain/grupo_estudo.dart';
import 'package:campus_connect_interface/features/grupos/domain/nivel_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/painel_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/args_navegacao_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/mensagem_chat_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/secao_detalhe_grupo.dart';
import 'package:campus_connect_interface/features/grupos/presentation/cartao_painel_grupo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GroupProfileScreen extends StatefulWidget {
  const GroupProfileScreen({
    super.key,
    required this.groupId,
    this.initialGroup,
  });

  final String groupId;
  final StudyGroup? initialGroup;

  @override
  State<GroupProfileScreen> createState() => _GroupProfileScreenState();
}

class _GroupProfileScreenState extends State<GroupProfileScreen> {
  StudyGroup? _group;
  GroupContentPanel? _panel;
  bool _loading = true;
  Object? _error;
  bool _loadStarted = false;

  @override
  void initState() {
    super.initState();
    _group = widget.initialGroup;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadStarted) {
      _loadStarted = true;
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deps = DependencyScope.of(context);
      final feedRepo = deps.feedPostsRepository;
      final groupsRepo = deps.groupsRepository;

      final results = await Future.wait([
        feedRepo.listPosts(
          FeedPostsQuery(page: 1, limit: 50, groupIds: [widget.groupId]),
        ),
        groupsRepo.listLinkedEvents(widget.groupId),
        groupsRepo.listChatMessages(widget.groupId),
      ]);

      final posts = (results[0] as FeedPostsPage).items;
      final events = results[1] as List<Map<String, dynamic>>;
      final messages = results[2] as List<GroupChatMessage>;
      final memberIds = messages
          .map((m) => m.authorId)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _panel = GroupContentPanel(
          allPosts: posts,
          events: events,
          chatMemberIds: memberIds,
        );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  void _openSection(GroupDetailSection section) {
    context.push(
      '/groups/${widget.groupId}/conteudo/${section.name}',
      extra: GroupSectionRouteArgs(
        group: _group,
        panel: _panel,
        section: section,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = _group;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ApiErrorPlaceholder(
                  message: _error.toString(),
                  onRetry: _load,
                )
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    slivers: [
                      SliverToBoxAdapter(child: _GroupProfileHeader(group: g)),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            if (g != null) _StatsRow(group: g, panel: _panel!),
                            const SizedBox(height: 14),
                            if (_panel != null)
                              GroupPanelCard(
                                panel: _panel!,
                                onOpenSection: _openSection,
                                memberCount: g?.memberCount ?? 0,
                              ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => context.pop(),
                              icon: const Icon(Icons.chat_bubble_outline_rounded),
                              label: const Text('Voltar ao chat'),
                            ),
                            const SizedBox(height: 100),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _GroupProfileHeader extends StatelessWidget {
  const _GroupProfileHeader({required this.group});

  final StudyGroup? group;

  static const _bannerDeep = Color(0xFF0F172A);
  static const _bannerMid = Color(0xFF1E3A8A);

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    const bannerHeight = 118.0;
    const avatarR = 48.0;
    final title = group?.title ?? 'Grupo';
    final initials = title.isNotEmpty
        ? title.trim().split(RegExp(r'\s+')).take(2).map((w) => w[0]).join()
        : 'G';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SizedBox(
              height: bannerHeight + topPad,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_bannerDeep, _bannerMid, AppColors.primary],
                        stops: [0, 0.55, 1],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.52),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: topPad + 6,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => context.pop(),
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'Perfil do grupo',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: topPad + bannerHeight - avatarR,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: avatarR,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        initials.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (group != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: group!.isPrivate
                            ? const Color(0xFFFFF7ED)
                            : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        group!.isPrivate ? 'Privado' : 'Público',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: group!.isPrivate
                              ? const Color(0xFFB45309)
                              : const Color(0xFF047857),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(20, avatarR + 18, 20, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.4,
                ),
              ),
              if (group != null && group!.fieldOfStudy.isNotEmpty) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined,
                        size: 18, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        group!.fieldOfStudy,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              if (group != null && group!.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  group!.description,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (group != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Nível: ${group!.level.labelPt}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.group, required this.panel});

  final StudyGroup group;
  final GroupContentPanel panel;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _stat(
              icon: Icons.groups_2_outlined,
              value: '${group.memberCount}',
              label: 'Membros',
              tint: const Color(0xFF059669),
            ),
          ),
          _divider(),
          Expanded(
            child: _stat(
              icon: Icons.dynamic_feed_outlined,
              value: '${panel.postsTotal}',
              label: 'Posts',
              tint: const Color(0xFF0891B2),
            ),
          ),
          _divider(),
          Expanded(
            child: _stat(
              icon: Icons.event_available_outlined,
              value: '${panel.eventsTotal}',
              label: 'Eventos',
              tint: const Color(0xFF7C3AED),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(
      width: 1,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: AppColors.chipBorder.withValues(alpha: 0.75),
    );
  }

  Widget _stat({
    required IconData icon,
    required String value,
    required String label,
    required Color tint,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: tint),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
