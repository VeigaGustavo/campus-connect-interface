import 'package:campus_connect_interface/features/inicio/domain/tipo_item_descoberta.dart';

class DiscoverItem {
  const DiscoverItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.excerpt,
    required this.metaPrimary,
    required this.metaSecondary,
    required this.referenceId,
    required this.publishScope,
    this.publishGroupId,
  });

  final String id;
  final DiscoverKind kind;
  final String title;
  final String subtitle;
  final String excerpt;
  final String metaPrimary;
  final String metaSecondary;

  final String referenceId;
  final String publishScope;
  final String? publishGroupId;

  String? get visibilityLabel {
    if (publishScope == 'group' &&
        publishGroupId != null &&
        publishGroupId!.isNotEmpty) {
      return 'Grupo: $publishGroupId';
    }
    if (publishScope == 'all') return 'Todos';
    return null;
  }
}
