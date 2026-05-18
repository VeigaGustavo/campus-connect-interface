import 'dart:convert';

class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    this.body,
    this.code,
    this.message,
  });

  final int statusCode;
  final String? body;
  final String? code;
  final String? message;

  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  String get userFacingOrBody {
    final m = message?.trim();
    if (m != null && m.isNotEmpty) return m;
    final b = body?.trim();
    if (b != null && b.isNotEmpty) return b;
    return 'Erro HTTP $statusCode';
  }

  factory ApiException.fromResponse({
    required int statusCode,
    required String body,
  }) {
    String? code;
    String? message;
    if (body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          code = decoded['code']?.toString();
          message = decoded['message']?.toString();
        }
      } catch (_) {}
    }
    return ApiException(
      statusCode: statusCode,
      body: body.isEmpty ? null : body,
      code: code,
      message: message,
    );
  }

  @override
  String toString() {
    final m = message?.trim();
    if (m != null && m.isNotEmpty) return m;
    return 'ApiException($statusCode)${body != null ? ': $body' : ''}';
  }
}
