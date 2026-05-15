import 'package:campus_connect_interface/core/configuracao/configuracao_api.dart';

/// Converte path relativo (`/uploads/avatars/x.jpg`) em URL absoluta para
/// [Image.network] no Flutter Web (mesmo host da API).
String resolveApiMediaUrl(String raw) {
  final s = raw.trim();
  if (s.isEmpty) return '';
  if (s.startsWith('http://') || s.startsWith('https://') || s.startsWith('blob:')) {
    return s;
  }
  final base = ApiConfig.baseUrl;
  if (s.startsWith('/')) return '$base$s';
  return '$base/$s';
}

/// Lê a primeira chave não vazia do JSON (snake_case / camelCase do backend).
String mediaUrlFromJson(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final v = json[key];
    if (v is String && v.trim().isNotEmpty) {
      return resolveApiMediaUrl(v);
    }
  }
  return '';
}
