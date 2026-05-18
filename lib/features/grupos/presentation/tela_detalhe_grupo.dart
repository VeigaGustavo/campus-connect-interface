import 'dart:async';

import 'package:campus_connect_interface/app/provedor_dependencias.dart';
import 'package:campus_connect_interface/core/autenticacao/sessao_local.dart';
import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/widgets/snackbar_erro_api.dart';
import 'package:campus_connect_interface/features/grupos/data/servico_websocket_chat_grupo.dart';
import 'package:campus_connect_interface/features/grupos/domain/grupo_estudo.dart';
import 'package:campus_connect_interface/features/grupos/domain/mensagem_chat_grupo.dart';
import 'package:campus_connect_interface/features/grupos/presentation/widgets/painel_chat_grupo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GroupDetailScreen extends StatefulWidget {
  const GroupDetailScreen({
    super.key,
    required this.groupId,
    this.initialGroup,
  });

  final String groupId;
  final StudyGroup? initialGroup;

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  StudyGroup? _group;

  final _chatController = TextEditingController();
  final _chatScroll = ScrollController();
  final _ws = GroupChatWebSocketService();

  List<GroupChatMessage> _messages = [];

  String _userId = '';
  String _userName = '';
  String _accessToken = '';
  final Map<String, String> _authorNamesById = {};
  bool _wsConnected = false;
  bool _chatLoading = true;
  bool _sending = false;
  Timer? _pollTimer;
  bool _chatStarted = false;

  @override
  void initState() {
    super.initState();
    _group = widget.initialGroup;
  }

  Future<void> _bootstrap() async {
    final session = await LocalSessionStore.read();
    if (!mounted) return;
    if (session == null) {
      context.go('/login');
      return;
    }
    _userId = session.userId;
    _accessToken = session.accessToken;
    _userName = session.login;

    try {
      final profile =
          await DependencyScope.of(context).profileRepository.getCurrentProfile();
      if (profile.name.trim().isNotEmpty) {
        _userName = profile.name.trim();
      }
    } catch (_) {}

    if (_userId.isNotEmpty && _userName.isNotEmpty) {
      _authorNamesById[_userId] = _userName;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_chatStarted) {
      _chatStarted = true;
      _startChat();
    }
  }

  Future<void> _startChat() async {
    await _bootstrap();
    if (!mounted || _accessToken.isEmpty) return;

    await _loadChatHistory();
    await _connectWs();
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadChatHistory(silent: true);
    });
  }

  Future<void> _connectWs() async {
    try {
      final api = DependencyScope.of(context).apiClient;
      final uri = api.groupChatWsUri(widget.groupId, accessToken: _accessToken);
      await _ws.connect(uri: uri, accessToken: _accessToken);
      _ws.messages.listen((m) {
        if (!mounted) return;
        if (m.groupId.isNotEmpty && m.groupId != widget.groupId) return;
        setState(() => _mergeMessages([m]));
        _scrollChatToEnd();
      });
      if (mounted) setState(() => _wsConnected = true);
    } catch (_) {
      if (mounted) setState(() => _wsConnected = false);
    }
  }

  Future<void> _loadChatHistory({bool silent = false}) async {
    if (!silent) setState(() => _chatLoading = true);
    try {
      final repo = DependencyScope.of(context).groupsRepository;
      final list = await repo.listChatMessages(widget.groupId);
      if (!mounted) return;
      setState(() {
        _mergeMessages(list);
        _chatLoading = false;
      });
      _scrollChatToEnd();
    } catch (_) {
      if (!mounted) return;
      setState(() => _chatLoading = false);
    }
  }

  void _mergeMessages(List<GroupChatMessage> incoming) {
    final byId = {for (final m in _messages) m.id: m};
    for (final m in incoming) {
      if (m.id.isEmpty) continue;
      byId[m.id] = m;
      final name = m.authorName?.trim();
      if (name != null && name.isNotEmpty && m.authorId.isNotEmpty) {
        _authorNamesById[m.authorId] = name;
      }
    }
    _messages = byId.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  void _scrollChatToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chatScroll.hasClients) return;
      _chatScroll.animateTo(
        _chatScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final repo = DependencyScope.of(context).groupsRepository;
      final saved = await repo.sendChatMessage(widget.groupId, text);
      final enriched = saved.copyWith(
        authorName: _userName.isNotEmpty ? _userName : 'Você',
      );
      _chatController.clear();
      setState(() => _mergeMessages([enriched]));
      if (_wsConnected) {
        _ws.broadcastMessage(enriched);
      }
      _scrollChatToEnd();
    } catch (e) {
      if (!mounted) return;
      showFloatingSnackBar(context, 'Não foi possível enviar: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _openGroupProfile() {
    context.push(
      '/groups/${widget.groupId}/perfil',
      extra: _group,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _ws.dispose();
    _chatController.dispose();
    _chatScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _group?.title ?? 'Grupo';
    final subtitle = _group?.fieldOfStudy ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: InkWell(
          onTap: _openGroupProfile,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 22,
                            color: AppColors.textSecondary.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          'Ver perfil · $subtitle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Perfil do grupo',
            onPressed: _openGroupProfile,
            icon: const Icon(Icons.info_outline_rounded),
          ),
        ],
      ),
      body: _chatLoading
          ? const Center(child: CircularProgressIndicator())
          : GroupChatPanel(
              messages: _messages,
              currentUserId: _userId,
              currentUserName: _userName,
              authorNamesById: _authorNamesById,
              controller: _chatController,
              onSend: _sendMessage,
              sending: _sending,
              wsConnected: _wsConnected,
              scrollController: _chatScroll,
            ),
    );
  }
}
