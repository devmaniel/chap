/// One delivered message in a conversation.
class Message {
  const Message({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isFromYou,
    this.imagePaths = const [],
  });

  final String id;
  final String text;
  final DateTime sentAt;

  /// False when the AI friend wrote it.
  final bool isFromYou;
  final List<String> imagePaths;
}
