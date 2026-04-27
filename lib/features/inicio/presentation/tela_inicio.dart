import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/barra_pesquisa_campus.dart';
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
  List<HomeFeedItem> _items = [];
  bool _loading = true;
  String _query = '';
  bool _initialLoadScheduled = false;
  static const _myGroupIds = <String>['grp-001', 'grp-002'];

  @override
  void initState() {
    super.initState();
    _search.addListener(() {
      setState(() => _query = _search.text.trim().toLowerCase());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLoadScheduled) return;
    _initialLoadScheduled = true;
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final repo = DependencyScope.of(context).homeFeedRepository;
      final items = await repo.loadFeed(_filter, groupIds: _myGroupIds);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<HomeFeedItem> get _visible {
    if (_query.isEmpty) return _items;
    return _items.where((e) {
      final t = '${e.title} ${e.subtitle} ${e.excerpt}'.toLowerCase();
      return t.contains(_query);
    }).toList();
  }

  void _onFeedItemTap(HomeFeedItem item) {
    switch (item.kind) {
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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: CustomScrollView(
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
                  hint: 'Buscar no feed: vagas, eventos, campus feed e avisos',
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
                          await _load();
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : AppColors.textSecondary,
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
            else if (_visible.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text(
                    'Nenhum resultado para esta combinação.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final item = _visible[i];
                    return HomeFeedCard(
                      item: item,
                      onTap: () => _onFeedItemTap(item),
                    );
                  }, childCount: _visible.length),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
