import 'dart:convert';

import 'package:campus_connect_interface/core/rede/contratos_auth.dart';
import 'package:campus_connect_interface/core/rede/contratos_conteudo.dart';
import 'package:campus_connect_interface/core/rede/excecao_api.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CampusApiClient {
  CampusApiClient({
    required String baseUrl,
    http.Client? httpClient,
  })  : _base = baseUrl.replaceAll(RegExp(r'/$'), ''),
        _http = httpClient ?? http.Client();

  final String _base;
  final http.Client _http;
  String? _accessToken;

  static const _acceptHeaders = <String, String>{
    'Accept': 'application/json',
  };
  static const _jsonHeaders = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Uri _uri(String path, [Map<String, String>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    final u = Uri.parse('$_base$p');
    return query == null || query.isEmpty ? u : u.replace(queryParameters: query);
  }

  Future<dynamic> get(
    String path, {
    Map<String, String>? query,
    bool requiresAuth = false,
  }) async {
    final res = await _http.get(
      _uri(path, query),
      headers: _headersForRequest(
        requiresAuth: requiresAuth,
        includeJsonContentType: false,
      ),
    );
    _ensureSuccess(res);
    final body = res.body;
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }

  /// `multipart/form-data` — não definir `Content-Type` manualmente (boundary automático).
  Future<dynamic> postMultipart(
    String path, {
    Map<String, String>? query,
    Map<String, String> fields = const {},
    required List<http.MultipartFile> files,
    bool requiresAuth = true,
  }) async {
    final uri = _uri(path, query);
    final request = http.MultipartRequest('POST', uri)
      ..fields.addAll(fields)
      ..files.addAll(files);
    request.headers['Accept'] = 'application/json';
    if (kDebugMode) {
      var total = 0;
      for (final f in files) {
        total += f.length;
        debugPrint(
          '[HTTP] multipart: field="${f.field}" bytes=${f.length} filename=${f.filename}',
        );
      }
      debugPrint('[HTTP] multipart total file bytes=$total fields=${fields.length}');
    }
    if (requiresAuth) {
      final token = _accessToken;
      if (token == null || token.isEmpty) {
        throw StateError(
          'Requisicao autenticada sem token. Faça login antes de chamar este endpoint.',
        );
      }
      request.headers['Authorization'] = 'Bearer $token';
    }
    final streamed = await _http.send(request);
    final res = await http.Response.fromStream(streamed);
    _ensureSuccess(res);
    final payload = res.body;
    if (payload.isEmpty) return null;
    return jsonDecode(payload);
  }

  Future<dynamic> post(
    String path, {
    Map<String, String>? query,
    Object? body,
    bool requiresAuth = false,
  }) async {
    final res = await _http.post(
      _uri(path, query),
      headers: _headersForRequest(
        requiresAuth: requiresAuth,
        includeJsonContentType: true,
      ),
      body: body == null ? null : jsonEncode(body),
    );
    _ensureSuccess(res);
    final payload = res.body;
    if (payload.isEmpty) return null;
    return jsonDecode(payload);
  }

  Future<dynamic> put(
    String path, {
    Map<String, String>? query,
    Object? body,
    bool requiresAuth = false,
  }) async {
    final res = await _http.put(
      _uri(path, query),
      headers: _headersForRequest(
        requiresAuth: requiresAuth,
        includeJsonContentType: true,
      ),
      body: body == null ? null : jsonEncode(body),
    );
    _ensureSuccess(res);
    final payload = res.body;
    if (payload.isEmpty) return null;
    return jsonDecode(payload);
  }

  Future<dynamic> delete(
    String path, {
    Map<String, String>? query,
    Object? body,
    bool requiresAuth = false,
  }) async {
    final req = http.Request('DELETE', _uri(path, query))
      ..headers.addAll(
        _headersForRequest(
          requiresAuth: requiresAuth,
          includeJsonContentType: true,
        ),
      );
    if (body != null) {
      req.body = jsonEncode(body);
    }
    final streamed = await _http.send(req);
    final res = await http.Response.fromStream(streamed);
    _ensureSuccess(res);
    final payload = res.body;
    if (payload.isEmpty) return null;
    return jsonDecode(payload);
  }

  Future<LoginResponseDto> login({
    required String email,
    required String senha,
  }) async {
    final dto = LoginRequestDto(email: email, password: senha);
    final raw = await post('/api/auth/login', body: dto.toJson());
    final response = LoginResponseDto.fromJson(raw as Map<String, dynamic>);
    _accessToken = response.accessToken;
    return response;
  }

  Future<RegisterResponseDto> register(RegisterRequestDto dto) async {
    final raw = await post('/api/auth/register', body: dto.toJson());
    return RegisterResponseDto.fromJson(raw as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> me() async {
    final raw = await get('/api/auth/me', requiresAuth: true);
    return raw as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> createGroup(Map<String, dynamic> payload) async {
    final raw = await post('/api/groups', body: payload, requiresAuth: true);
    return _asJsonObjectOrEmpty(raw);
  }

  Future<Map<String, dynamic>> createCommunity(
    Map<String, dynamic> payload,
  ) async {
    final raw = await post(
      '/api/communities',
      body: payload,
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<Map<String, dynamic>> createOpportunity(
    OpportunityPayload payload,
  ) async {
    final raw = await post(
      '/api/opportunities',
      body: payload.toJson(),
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<Map<String, dynamic>> updateOpportunity(
    String id,
    OpportunityPayload payload,
  ) async {
    final raw = await put(
      '/api/opportunities/$id',
      body: payload.toJson(),
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<void> deleteOpportunity(String id) async {
    await delete('/api/opportunities/$id', requiresAuth: true);
  }

  Future<List<Map<String, dynamic>>> getOpportunityApplicants(String id) async {
    final raw = await get('/api/opportunities/$id/applicants', requiresAuth: true);
    return _asJsonListOfObjects(raw);
  }

  Future<Map<String, dynamic>> createEvent(EventPayload payload) async {
    final raw = await post(
      '/api/events',
      body: payload.toJson(),
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<Map<String, dynamic>> updateEvent(String id, EventPayload payload) async {
    final raw = await put(
      '/api/events/$id',
      body: payload.toJson(),
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<void> deleteEvent(String id) async {
    await delete('/api/events/$id', requiresAuth: true);
  }

  Future<Map<String, dynamic>> updateGroup(
    String id,
    Map<String, dynamic> payload,
  ) async {
    final raw = await put('/api/groups/$id', body: payload, requiresAuth: true);
    return _asJsonObjectOrEmpty(raw);
  }

  Future<void> deleteGroup(String id) async {
    await delete('/api/groups/$id', requiresAuth: true);
  }

  Future<List<Map<String, dynamic>>> listGroupChatMessages(String groupId) async {
    final raw = await get('/api/groups/$groupId/chat/messages', requiresAuth: true);
    return _asJsonListOfObjects(raw);
  }

  Future<Map<String, dynamic>> createGroupChatMessage(
    String groupId,
    String text,
  ) async {
    final raw = await post(
      '/api/groups/$groupId/chat/messages',
      body: {'text': text},
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Uri groupChatWsUri(String groupId) {
    final base = Uri.parse(_base);
    final wsScheme = base.scheme == 'https' ? 'wss' : 'ws';
    return base.replace(
      scheme: wsScheme,
      path: '/api/groups/$groupId/chat/ws',
      queryParameters: null,
    );
  }

  Future<List<Map<String, dynamic>>> listGroupFiles(String groupId) async {
    final raw = await get('/api/groups/$groupId/files', requiresAuth: true);
    return _asJsonListOfObjects(raw);
  }

  Future<Map<String, dynamic>> createGroupFile(
    String groupId,
    GroupFilePayload payload,
  ) async {
    final raw = await post(
      '/api/groups/$groupId/files',
      body: payload.toJson(),
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<List<Map<String, dynamic>>> listGroupMeetings(String groupId) async {
    final raw = await get('/api/groups/$groupId/meetings', requiresAuth: true);
    return _asJsonListOfObjects(raw);
  }

  Future<Map<String, dynamic>> createGroupMeeting(
    String groupId,
    GroupMeetingPayload payload,
  ) async {
    final raw = await post(
      '/api/groups/$groupId/meetings',
      body: payload.toJson(),
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<List<Map<String, dynamic>>> listGroupEvents(String groupId) async {
    final raw = await get('/api/groups/$groupId/events', requiresAuth: true);
    return _asJsonListOfObjects(raw);
  }

  Future<Map<String, dynamic>> createGroupEventLink(
    String groupId,
    String eventId,
  ) async {
    final raw = await post(
      '/api/groups/$groupId/events',
      body: {'event_id': eventId},
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<List<Map<String, dynamic>>> listGroupReadings(String groupId) async {
    final raw = await get('/api/groups/$groupId/readings', requiresAuth: true);
    return _asJsonListOfObjects(raw);
  }

  Future<Map<String, dynamic>> createGroupReadingLink(
    String groupId,
    String readingId,
  ) async {
    final raw = await post(
      '/api/groups/$groupId/readings',
      body: {'reading_id': readingId},
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<Map<String, dynamic>> createWeeklyReading(WeeklyReadingPayload payload) async {
    final raw = await post(
      '/api/reading/weekly',
      body: payload.toJson(),
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<Map<String, dynamic>> updateWeeklyReading(
    String id,
    WeeklyReadingPayload payload,
  ) async {
    final raw = await put(
      '/api/reading/weekly/$id',
      body: payload.toJson(),
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<void> deleteWeeklyReading(String id) async {
    await delete('/api/reading/weekly/$id', requiresAuth: true);
  }

  Future<Map<String, dynamic>> createAdminUser(AdminUserPayload payload) async {
    final raw = await post(
      '/api/admin/users',
      body: payload.toJson(),
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  Future<Map<String, dynamic>> createUniversityNotice(
    Map<String, dynamic> payload,
  ) async {
    final raw = await post(
      '/api/university/notices',
      body: payload,
      requiresAuth: true,
    );
    return _asJsonObjectOrEmpty(raw);
  }

  void setAccessToken(String token) {
    _accessToken = token;
  }

  void clearAccessToken() {
    _accessToken = null;
  }

  Map<String, String> _headersForRequest({
    required bool requiresAuth,
    required bool includeJsonContentType,
  }) {
    final base = includeJsonContentType
        ? Map<String, String>.from(_jsonHeaders)
        : Map<String, String>.from(_acceptHeaders);
    if (requiresAuth) {
      final token = _accessToken;
      if (token == null || token.isEmpty) {
        throw StateError(
          'Requisicao autenticada sem token. Faça login antes de chamar este endpoint.',
        );
      }
      base['Authorization'] = 'Bearer $token';
    }
    return base;
  }

  Map<String, dynamic> _asJsonObjectOrEmpty(dynamic raw) {
    if (raw == null) return <String, dynamic>{};
    return raw as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> _asJsonListOfObjects(dynamic raw) {
    if (raw == null) return <Map<String, dynamic>>[];
    final list = raw as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  void _ensureSuccess(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw ApiException(statusCode: res.statusCode, body: res.body);
  }
}
