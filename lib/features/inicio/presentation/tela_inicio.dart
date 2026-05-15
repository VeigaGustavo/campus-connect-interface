import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/barra_pesquisa_campus.dart';
import 'package:campus_connect_interface/features/feed/domain/repositorio_feed_posts.dart';
import 'package:campus_connect_interface/features/feed/presentation/modal_criar_post_feed.dart';
import 'package:campus_connect_interface/features/feed/presentation/widgets/cartao_post_feed_lista.dart';
import 'package:campus_connect_interface/features/inicio/domain/filtro_feed_inicio.dart';
import 'package:campus_connect_interface/features/inicio/domain/item_feed_inicio.dart';
import 'package:campus_connect_interface/features/inicio/domain/tipo_item_feed_inicio.dart';
import 'package:campus_connect_interface/features/inicio/presentation/widgets/cartao_item_feed_inicio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  HomeFeedFilter _filter = HomeFeedFilter.all;
  final _search = TextEditingController();
  final _scrollController = ScrollController();

  List<HomeFeedItem> _campusItems = [];
  List<FeedPostDetail> _posts = [];
  int _postsPage = 1;
  bool _hasMorePosts = true;

  bool _loading = true;
  bool _loadingMorePosts = false;
  String _query = '';
  bool _initialLoadScheduled = false;

  /// IDs reais de grupos do usuário (UUID). Vazio = só posts `publish_scope: all`.
  static const _myGroupIds = <String>[];
  static const _postsPageSize = 20;

  bool get _showsPostsTimeline => _filter == HomeFeedFilter.all;

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLoadScheduled) return;
    _initialLoadScheduled = true;
    _load(refresh: true);
  }

  @override
  void dispose() {
    _search.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_showsPostsTimeline || !_hasMorePosts || _loadingMorePosts || _loading) {
      return;
    }
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 280) {
      _loadMorePosts();
    }
  }

  Future<void> _load({required bool refresh}) async {
    if (refresh) {
      setState(() {
        _loading = true;
        _postsPage = 1;
        _hasMorePosts = true;
        _posts = [];
        _campusItems = [];
      });
    }

    try {
      if (_showsPostsTimeline) {
        final feedRepo = DependencyScope.of(context).feedPostsRepository;
        final page = await feedRepo.listPosts(
          FeedPostsQuery(
            page: _postsPage,
            limit: _postsPageSize,
            groupIds: _myGroupIds,
          ),
        );
        if (!mounted) return;
        setState(() {
          if (refresh) {
            _posts = page.items;
          } else {
            _posts = [..._posts, ...page.items];
          }
          _hasMorePosts = page.hasMore;
          _postsPage = page.page + 1;
        });
      } else {
        final repo = DependencyScope.of(context).homeFeedRepository;
        final items = await repo.loadFeed(_filter, groupIds: _myGroupIds);
        if (!mounted) return;
        setState(() => _campusItems = items);
      }
    } catch (_) {
      if (!mounted) return;
      if (refresh) {
        setState(() {
          _posts = [];
          _campusItems = [];
          _hasMorePosts = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMorePosts() async {
    if (!_hasMorePosts || _loadingMorePosts) return;
    setState(() => _loadingMorePosts = true);
    try {
      final feedRepo = DependencyScope.of(context).feedPostsRepository;
      final page = await feedRepo.listPosts(
        FeedPostsQuery(
          page: _postsPage,
          limit: _postsPageSize,
          groupIds: _myGroupIds,
        ),
      );
      if (!mounted) return;
      setState(() {
        _posts = [..._posts, ...page.items];
        _hasMorePosts = page.hasMore;
        _postsPage = page.page + 1;
      });
    } catch (_) {
      // mantém lista atual
    } finally {
      if (mounted) setState(() => _loadingMorePosts = false);
    }
  }

  List<FeedPostDetail> get _visiblePosts {
    if (_query.isEmpty) return _posts;
    return _posts.where((p) {
      final t =
          '${p.text} ${p.author.name} ${p.contentKind}'.toLowerCase();
      return t.contains(_query);
    }).toList();
  }

  List<HomeFeedItem> get _visibleCampus {
    if (_query.isEmpty) return _campusItems;
    return _campusItems.where((e) {
      final t = '${e.title} ${e.subtitle} ${e.excerpt}'.toLowerCase();
      return t.contains(_query);
    }).toList();
  }

  Future<void> _openCreatePost() async {
    final postId = await showCreateFeedPostModal(context);
    if (!mounted || postId == null) return;
    await _load(refresh: true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post publicado.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    context.push('/feed/posts/${Uri.encodeComponent(postId)}');
  }

  void _onFeedItemTap(HomeFeedItem item) {
    switch (item.kind) {
      case HomeFeedKind.post:
        context.push('/feed/posts/${Uri.encodeComponent(item.referenceId)}');
        return;
      case HomeFeedKind.opportunity:
        context.push('/opportunity/${Uri.encodeComponent(item.referenceId)}');
        return;
      case HomeFeedKind.event:
        context.push('/events');
        return;
      case HomeFeedKind.studyGroup:
        context.go('/groups');
        return;
      case HomeFeedKind.reading:
        context.go('/reading');
        return;
      case HomeFeedKind.project:
      case HomeFeedKind.notice:
        break;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Este tipo ainda não possui detalhe por ID no app: ${item.title}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showPosts = _showsPostsTimeline;
    final visiblePosts = _visiblePosts;
    final visibleCampus = _visibleCampus;
    final isEmpty = showPosts ? visiblePosts.isEmpty : visibleCampus.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _openCreatePost,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_outlined),
        label: const Text(
          'Novo post',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        color: AppColors.primary,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Feed',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/events'),
                      icon: const Icon(Icons.event_outlined),
                      color: AppColors.textPrimary,
                      tooltip: 'Eventos',
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverToBoxAdapter(
                child: CampusSearchBar(
                  hint: showPosts
                      ? 'Buscar posts'
                      : 'Buscar no feed: vagas, eventos, campus feed e avisos',
                  controller: _search,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  scrollDirection: Axis.horizontal,
                  children: HomeFeedFilter.values.map((f) {
                    final selected = _filter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(f.label),
                        selected: selected,
                        onSelected: (v) async {
                          if (!v) return;
                          setState(() => _filter = f);
                          await _load(refresh: true);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                          side: BorderSide(
                            color: selected
                                ? AppColors.primary
                                : AppColors.chipBorder,
                          ),
                        ),
                        backgroundColor: AppColors.surface,
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    showPosts
                        ? 'Nenhum post ainda. Seja o primeiro a publicar!'
                        : 'Nenhum resultado para esta combinação.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else if (showPosts)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i >= visiblePosts.length) {
                        return _loadingMorePosts
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : const SizedBox(height: 24);
                      }
                      final post = visiblePosts[i];
                      return FeedPostListCard(
                        post: post,
                        onTap: () => context.push(
                          '/feed/posts/${Uri.encodeComponent(post.id)}',
                        ),
                      );
                    },
                    childCount: visiblePosts.length +
                        (_loadingMorePosts || _hasMorePosts ? 1 : 0),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final item = visibleCampus[i];
                      return HomeFeedCard(
                        item: item,
                        onTap: () => _onFeedItemTap(item),
                      );
                    },
                    childCount: visibleCampus.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
