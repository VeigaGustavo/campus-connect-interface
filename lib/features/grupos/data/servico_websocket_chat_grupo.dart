import 'dart:async';
import 'dart:convert';

import 'package:campus_connect_interface/features/grupos/domain/mensagem_chat_grupo.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class GroupChatWebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  final _incoming = StreamController<GroupChatMessage>.broadcast();

  Stream<GroupChatMessage> get messages => _incoming.stream;

  bool get isConnected => _channel != null;

  Future<void> connect({
    required Uri uri,
    required String accessToken,
  }) async {
    await disconnect();
    final target = uri.replace(
      queryParameters: {
        ...uri.queryParameters,
        if (accessToken.isNotEmpty) 'access_token': accessToken,
      },
    );
    _channel = WebSocketChannel.connect(target);
    _subscription = _channel!.stream.listen(
      _onPayload,
      onError: (_) {},
      onDone: () {},
    );
  }

  void _onPayload(dynamic payload) {
    if (payload is! String) return;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) return;
      final event = decoded['event']?.toString();
      final body = decoded['message'];
      if (event == 'chat_message' && body is Map<String, dynamic>) {
        _incoming.add(_mapMessage(body));
        return;
      }
      if (decoded.containsKey('id') && decoded.containsKey('text')) {
        _incoming.add(_mapMessage(decoded));
      }
    } catch (_) {
      if (payload.trim().isNotEmpty) {
        _incoming.add(
          GroupChatMessage(
            id: 'ws-${DateTime.now().microsecondsSinceEpoch}',
            groupId: '',
            authorId: '',
            text: payload,
            createdAt: DateTime.now(),
          ),
        );
      }
    }
  }

  GroupChatMessage _mapMessage(Map<String, dynamic> j) {
    var authorName = j['author_name']?.toString().trim();
    if ((authorName == null || authorName.isEmpty) && j['author'] is Map) {
      final map = Map<String, dynamic>.from(j['author'] as Map);
      authorName = (map['name'] ?? map['nome'])?.toString().trim();
    }

    return GroupChatMessage(
      id: j['id']?.toString() ?? '',
      groupId: j['group_id']?.toString() ?? '',
      authorId: j['author_id']?.toString() ?? '',
      text: (j['text'] ?? '') as String,
      createdAt: DateTime.tryParse((j['created_at'] ?? '').toString()) ??
          DateTime.now(),
      authorName:
          authorName != null && authorName.isNotEmpty ? authorName : null,
    );
  }

  void broadcastMessage(GroupChatMessage message) {
    final payload = jsonEncode({
      'event': 'chat_message',
      'message': {
        'id': message.id,
        'group_id': message.groupId,
        'author_id': message.authorId,
        'author_name': message.authorName,
        'text': message.text,
        'created_at': message.createdAt.toUtc().toIso8601String(),
      },
    });
    _channel?.sink.add(payload);
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _incoming.close();
  }
}
