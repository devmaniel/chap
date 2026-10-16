import '../../../domain/models/chat/chat.dart';
import '../../../utils/result.dart';
import 'chat_repository.dart';

/// In-memory chats for building the app before the server exists.
class ChatRepositoryLocal implements ChatRepository {
  ChatRepositoryLocal({
    this.latency = const Duration(milliseconds: 600),
    List<Chat> chats = const [],
  }) : _chats = chats;

  /// Simulated round trip, so loading states are visible.
  final Duration latency;

  final List<Chat> _chats;

  @override
  Future<Result<List<Chat>>> getChats() async {
    await Future<void>.delayed(latency);
    final newestFirst = [..._chats]
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
    return Result.ok(newestFirst);
  }
}
