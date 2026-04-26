class ApiException implements Exception {
  ApiException({required this.statusCode, this.body});

  final int statusCode;
  final String? body;

  bool get isNotFound => statusCode == 404;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;

  @override
  String toString() =>
      'ApiException($statusCode)${body != null ? ': $body' : ''}';
}
