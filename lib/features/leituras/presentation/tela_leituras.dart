import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/autorizacao/permissoes_interface.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/mensagem_erro_api.dart';
import 'package:campus_connect_interface/core/widgets/snackbar_erro_api.dart';
import 'package:campus_connect_interface/core/widgets/cartao_contorno_suave.dart';
import 'package:campus_connect_interface/features/leituras/domain/item_leitura_semanal.dart';
import 'package:campus_connect_interface/features/leituras/presentation/modal_criar_leitura.dart';
import 'package:flutter/material.dart';

class ReadingScreen extends StatefulWidget {
  const ReadingScreen({super.key});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  Future<List<WeeklyReadingItem>>? _future;
  WeeklyReadingKind? _filterKind;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _loadInitial();
  }

  Future<List<WeeklyReadingItem>> _loadInitial() {
    return DependencyScope.of(context).readingRepository.getWeeklyHighlights(
          kind: _filterKind,
        );
  }

  Future<void> _reload() async {
    final next = _loadInitial();
    setState(() => _future = next);
    await next;
  }

  void _setFilter(WeeklyReadingKind? kind) {
    if (_filterKind == kind) return;
    setState(() {
      _filterKind = kind;
      _future = _loadInitial();
    });
  }

  Future<void> _openCreate() async {
    final created = await showCreateWeeklyReadingModal(context);
    if (created == true && mounted) {
      await _reload();
      if (!mounted) return;
      showFloatingSnackBar(context, 'Leitura publicada com sucesso.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final canCreate = UiPermissions.canManageReadings(
      DependencyScope.of(context).currentUserRole,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: _openCreate,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Nova leitura',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: FutureBuilder<List<WeeklyReadingItem>>(
        future: _future,
        builder: (context, snap) {
          if (_future == null ||
              snap.connectionState != ConnectionState.done) {
            return Center(
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary.withValues(alpha: 0.85),
              ),
            );
          }
          if (snap.hasError) {
            return ApiErrorPlaceholder(
              message: snap.error.toString(),
              onRetry: _reload,
            );
          }
          final items = snap.data ?? [];
          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: _reload,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, top + 16, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Leituras da semana',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.4,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Notícias do campus, revistas e artigos.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.35,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _kindFilterChip(
                              label: 'Todas',
                              selected: _filterKind == null,
                              onTap: () => _setFilter(null),
                            ),
                            _kindFilterChip(
                              label: WeeklyReadingKind.campusNews.labelPt,
                              selected:
                                  _filterKind == WeeklyReadingKind.campusNews,
                              onTap: () =>
                                  _setFilter(WeeklyReadingKind.campusNews),
                              icon: Icons.newspaper_rounded,
                            ),
                            _kindFilterChip(
                              label: WeeklyReadingKind.magazine.labelPt,
                              selected:
                                  _filterKind == WeeklyReadingKind.magazine,
                              onTap: () =>
                                  _setFilter(WeeklyReadingKind.magazine),
                              icon: Icons.auto_stories_outlined,
                            ),
                            _kindFilterChip(
                              label: WeeklyReadingKind.article.labelPt,
                              selected:
                                  _filterKind == WeeklyReadingKind.article,
                              onTap: () =>
                                  _setFilter(WeeklyReadingKind.article),
                              icon: Icons.article_outlined,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _filterKind == null
                              ? 'Nenhuma leitura publicada ainda.'
                              : 'Nenhuma leitura deste tipo.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = items[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _ReadingCard(item: item),
                          );
                        },
                        childCount: items.length,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _kindFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.chipBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : AppColors.primary,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard({required this.item});

  final WeeklyReadingItem item;

  Color get _accent => switch (item.kind) {
        WeeklyReadingKind.campusNews => const Color(0xFF2563EB),
        WeeklyReadingKind.magazine => const Color(0xFFCA8A04),
        WeeklyReadingKind.article => const Color(0xFF059669),
      };

  bool get _hasImage => item.imageUrl.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_hasImage)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _imagePlaceholder(),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(14, _hasImage ? 14 : 16, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        item.kind.labelPt,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.35,
                          color: _accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 14,
                            color: AppColors.textSecondary
                                .withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              item.metaLabel,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.source,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.excerpt,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: _accent.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported_outlined,
        size: 40,
        color: _accent.withValues(alpha: 0.6),
      ),
    );
  }
}
