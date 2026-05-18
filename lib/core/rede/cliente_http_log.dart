import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LoggingHttpClient extends http.BaseClient {
  LoggingHttpClient(this._inner);

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (kDebugMode) {
      debugPrint('[HTTP] -> ${request.method} ${request.url}');
    }
    final sw = Stopwatch()..start();
    try {
      final response = await _inner.send(request);
      if (kDebugMode) {
        debugPrint(
          '[HTTP] <- ${response.statusCode} ${request.url} (${sw.elapsedMilliseconds}ms)',
        );
      }
      return response;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[HTTP] !! ${request.url} $e');
        debugPrint('$st');
      }
      rethrow;
    }
  }

  @override
  void close() => _inner.close();
}
