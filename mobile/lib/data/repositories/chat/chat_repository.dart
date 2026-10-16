import '../../../domain/models/chat/chat.dart';
import '../../../utils/result.dart';

abstract class ChatRepository {
  /// Every chat, newest first.
  Future<Result<List<Chat>>> getChats();
}
