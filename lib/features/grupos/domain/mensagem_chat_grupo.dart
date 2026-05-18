class GroupChatMessage {
  const GroupChatMessage({
    required this.id,
    required this.groupId,
    required this.authorId,
    required this.text,
    required this.createdAt,
    this.authorName,
  });

  final String id;
  final String groupId;
  final String authorId;
  final String text;
  final DateTime createdAt;
  final String? authorName;

  GroupChatMessage copyWith({String? authorName}) {
    return GroupChatMessage(
      id: id,
      groupId: groupId,
      authorId: authorId,
      text: text,
      createdAt: createdAt,
      authorName: authorName ?? this.authorName,
    );
  }

  String displayLabel({
    required String currentUserId,
    required String currentUserName,
    Map<String, String> namesByAuthorId = const {},
  }) {
    final fromMessage = authorName?.trim();
    if (fromMessage != null && fromMessage.isNotEmpty) return fromMessage;
    if (authorId == currentUserId) {
      return currentUserName.isNotEmpty ? currentUserName : 'Você';
    }
    final cached = namesByAuthorId[authorId]?.trim();
    if (cached != null && cached.isNotEmpty) return cached;
    return 'Participante';
  }
}
