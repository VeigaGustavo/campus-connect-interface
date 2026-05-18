List<dynamic> decodeJsonList(dynamic decoded) {
  if (decoded is List<dynamic>) return decoded;
  if (decoded is Map<String, dynamic>) {
    final items = decoded['items'];
    if (items is List<dynamic>) return items;
  }
  throw const FormatException('JSON inválido: esperado lista ou campo items');
}

List<dynamic> decodeJsonListEnvelope(dynamic decoded) {
  if (decoded == null) return const [];
  if (decoded is List<dynamic>) return decoded;
  if (decoded is Map<String, dynamic>) {
    const keys = <String>[
      'items',
      'data',
      'results',
      'content',
      'records',
      'opportunities',
      'feed',
      'cards',
      'rows',
      'history',
      'weekly',
      'readings',
      'highlights',
    ];
    for (final k in keys) {
      final v = decoded[k];
      if (v is List<dynamic>) return v;
    }
    return const [];
  }
  throw const FormatException(
    'JSON: esperado lista ou objeto com lista (items, data, …).',
  );
}

Map<String, dynamic> decodeJsonObject(dynamic decoded) {
  if (decoded is Map<String, dynamic>) return decoded;
  throw const FormatException('JSON inválido: esperado objeto');
}
