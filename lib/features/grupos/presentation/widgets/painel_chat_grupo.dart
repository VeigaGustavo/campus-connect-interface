import 'package:campus_connect_interface/core/theme/cores_aplicativo.dart';
import 'package:campus_connect_interface/core/util/formatacao_data_portugues.dart';
import 'package:campus_connect_interface/features/grupos/domain/mensagem_chat_grupo.dart';
import 'package:flutter/material.dart';

class GroupChatPanel extends StatelessWidget {
  const GroupChatPanel({
    super.key,
    required this.messages,
    required this.currentUserId,
    required this.currentUserName,
    required this.authorNamesById,
    required this.controller,
    required this.onSend,
    required this.sending,
    required this.wsConnected,
    required this.scrollController,
  });

  final List<GroupChatMessage> messages;
  final String currentUserId;
  final String currentUserName;
  final Map<String, String> authorNamesById;
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  final bool wsConnected;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (!wsConnected)
          Container(
            width: double.infinity,
            color: const Color(0xFFFFF7ED),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const Text(
              'Chat em modo HTTP (WebSocket indisponível). Mensagens atualizam ao enviar.',
              style: TextStyle(fontSize: 12, color: Color(0xFFB45309)),
            ),
          ),
        Expanded(
          child: messages.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhuma mensagem ainda.\nDiga olá ao grupo!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final mine = m.authorId == currentUserId;
                    final name = m.displayLabel(
                      currentUserId: currentUserId,
                      currentUserName: currentUserName,
                      namesByAuthorId: authorNamesById,
                    );
                    final when = formatDayMonthTimePt(m.createdAt);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: mine
                            ? CrossAxisAlignment.end
                            : CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(
                              left: mine ? 0 : 4,
                              right: mine ? 4 : 0,
                              bottom: 4,
                            ),
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: mine
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.sizeOf(context).width * 0.78,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? AppColors.primary
                                    : AppColors.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(16),
                                  topRight: const Radius.circular(16),
                                  bottomLeft: Radius.circular(mine ? 16 : 4),
                                  bottomRight: Radius.circular(mine ? 4 : 16),
                                ),
                                border: mine
                                    ? null
                                    : Border.all(color: AppColors.chipBorder),
                              ),
                              child: Text(
                                m.text,
                                style: TextStyle(
                                  color: mine
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  height: 1.35,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(
                              top: 4,
                              left: mine ? 0 : 4,
                              right: mine ? 4 : 0,
                            ),
                            child: Text(
                              when,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary
                                    .withValues(alpha: 0.9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
        Material(
          elevation: 8,
          color: AppColors.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        hintText: 'Mensagem...',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: sending ? null : onSend,
                    icon: sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
