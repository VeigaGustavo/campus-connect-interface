List<dynamic> decodeJsonList(dynamic decoded) {
  if (decoded is List<dynamic>) return decoded;
  if (decoded is Map<String, dynamic>) {
    final items = decoded['items'];
    if (items is List<dynamic>) return items;
  }
  throw const FormatException('JSON inválido: esperado lista ou campo items');
}

Map<String, dynamic> decodeJsonObject(dynamic decoded) {
  if (decoded is Map<String, dynamic>) return decoded;
  throw const FormatException('JSON inválido: esperado objeto');
}
