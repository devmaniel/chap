/// One conversation with an AI friend, as the inbox shows it.
class Chat {
  const Chat({
    required this.id,
    required this.friendName,
    required this.portraitAsset,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  final String id;
  final String friendName;
  final String portraitAsset;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  bool get isUnread => unreadCount > 0;
}
