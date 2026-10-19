/// One delivered message in a conversation.
class Message {
  const Message({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.isFromYou,
    this.imagePaths = const [],
    this.postId,
    this.callDuration,
  });

  final String id;
  final String text;
  final DateTime sentAt;

  /// False when the AI friend wrote it.
  final bool isFromYou;
  final List<String> imagePaths;

  /// The friend's post this message replies to.
  final String? postId;

  /// Set when this is the record of a voice call: how long it lasted.
  final Duration? callDuration;
}
