import 'package:campus_connect_interface/core/configuracao/configuracao_api.dart';

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

String mediaUrlFromJson(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final v = json[key];
    if (v is String && v.trim().isNotEmpty) {
      return resolveApiMediaUrl(v);
    }
  }
  return '';
}
