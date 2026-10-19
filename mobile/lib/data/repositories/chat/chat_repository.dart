import 'package:flutter/foundation.dart';

import '../../../domain/models/chat/chat.dart';
import '../../../domain/models/message/message.dart';
import '../../../domain/models/photo/photo.dart';
import '../../../utils/result.dart';

/// Unsent text and photos left in a chat's composer.
typedef Draft = ({String text, List<String> imagePaths});

abstract class ChatRepository extends ChangeNotifier {
  List<Chat>? get cachedChats;
  Chat? cachedChat(String chatId);
  List<Message>? cachedMessages(String chatId);

  /// The chat's unsent draft, or null when the composer is empty.
  Draft? draftFor(String chatId);

  /// Stores the draft; an empty one clears it.
  void saveDraft(String chatId, Draft draft);

  /// Every chat, newest first.
  Future<Result<List<Chat>>> getChats();

  Future<Result<Chat>> getChat(String chatId);

  /// Adds [chat] with its last message as the friend's first one, unless a
  /// chat with that id already exists. Returns the stored chat.
  Future<Result<Chat>> startChat(Chat chat);

  /// The conversation, oldest first.
  Future<Result<List<Message>>> getMessages(String chatId);

  /// Delivers your message and returns it as stored.
  Future<Result<Message>> sendMessage({
    required String chatId,
    required String text,
    List<String> imagePaths = const [],
    String? postId,
  });

  Future<Result<List<Photo>>> getPhotos(int page);

  Future<Result<List<String>>> getImagePaths(List<String> ids);

  Future<Result<void>> openPhotoSettings();

  /// Waits for the friend to answer the latest message.
  Future<Result<Message>> getReply(String chatId);
}

final class ChatNotFoundException implements Exception {
  const ChatNotFoundException();
}

final class PhotoAccessDeniedException implements Exception {
  const PhotoAccessDeniedException();
}
