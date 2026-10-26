import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../../../domain/models/chat/chat.dart';
import '../../../domain/models/message/message.dart';
import '../../../domain/models/photo/photo.dart';
import '../../../utils/result.dart';
import '../../services/api_service.dart';
import '../../services/image_compress_service.dart';
import '../../services/photo_library_service.dart';
import '../../services/voice_call_service.dart';
import '../auth/auth_repository.dart';
import 'chat_repository.dart';

/// Chats and messages on the Chap server, where friends reply through Gemini.
/// Drafts stay in memory. Photos stay on the phone: the server keeps only
/// their paths, and sees the photos themselves only while writing a reply.
/// Voice calls run through ElevenLabs from a pass the server hands out, and
/// the server keeps the record of each call.
class ChatRepositoryRemote extends ChatRepository {
  ChatRepositoryRemote({
    required ApiService apiService,
    required Map<String, String> portraitAssets,
    PhotoLibraryService? photoLibraryService,
    ImageCompressService? imageCompressService,
    VoiceCallService? voiceCallService,
  }) : _api = apiService,
       _portraitAssets = portraitAssets,
       _photoLibraryService = photoLibraryService ?? PhotoLibraryService(),
       _imageCompressService = imageCompressService ?? ImageCompressService(),
       _voiceCallService = voiceCallService ?? VoiceCallService() {
    // A call connecting or dropping changes isCallOnline.
    _voiceCallService.addListener(notifyListeners);
  }

  final ApiService _api;

  /// The bundled portrait for each friend id; the server holds no images.
  final Map<String, String> _portraitAssets;
  final PhotoLibraryService _photoLibraryService;
  final ImageCompressService _imageCompressService;
  final VoiceCallService _voiceCallService;

  Map<String, Chat> _chats = const {};
  bool _isInboxLoaded = false;
  Map<String, List<Message>> _messages = const {};
  Map<String, Draft> _drafts = const {};

  @override
  void dispose() {
    _voiceCallService.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  List<Chat>? get cachedChats => _isInboxLoaded ? _sorted() : null;

  @override
  Chat? cachedChat(String chatId) => _chats[chatId];

  @override
  List<Message>? cachedMessages(String chatId) => _messages[chatId];

  @override
  Draft? draftFor(String chatId) => _drafts[chatId];

  @override
  void saveDraft(String chatId, Draft draft) {
    final isEmpty = draft.text.trim().isEmpty && draft.imagePaths.isEmpty;
    if (isEmpty && !_drafts.containsKey(chatId)) return;
    _drafts = {
      for (final entry in _drafts.entries)
        if (entry.key != chatId) entry.key: entry.value,
      if (!isEmpty) chatId: draft,
    };
    notifyListeners();
  }

  @override
  Future<Result<List<Chat>>> getChats() async {
    switch (await _api.get('/api/chats')) {
      case Ok(value: final List<Object?> items):
        _chats = {
          for (final chat in items.map(_parseChat).nonNulls) chat.id: chat,
        };
        _isInboxLoaded = true;
        notifyListeners();
        return Result.ok(_sorted());
      case Ok():
        return const Result.error(FormatException('Expected a list'));
      case Error(:final error):
        return Result.error(_mapError(error));
    }
  }

  @override
  Future<Result<Chat>> getChat(String chatId) =>
      _storeChat(_api.get('/api/chats/$chatId'));

  /// Only the id of [chat] matters: the server opens it with the friend's own
  /// first hello.
  @override
  Future<Result<Chat>> startChat(Chat chat) =>
      _storeChat(_api.put('/api/chats/${chat.id}'));

  @override
  Future<Result<List<Message>>> getMessages(String chatId) async {
    switch (await _api.get('/api/chats/$chatId/messages')) {
      case Ok(value: final List<Object?> items):
        final messages = List<Message>.unmodifiable(
          items.map(_parseMessage).nonNulls,
        );
        _messages = {..._messages, chatId: messages};
        notifyListeners();
        return Result.ok(messages);
      case Ok():
        return const Result.error(FormatException('Expected a list'));
      case Error(:final error):
        return Result.error(_mapError(error));
    }
  }

  @override
  Future<Result<void>> markRead(String chatId) async {
    switch (await _api.post('/api/chats/$chatId/read')) {
      case Ok():
        _updateChat(chatId, (chat) => _summary(chat, unreadCount: 0));
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(_mapError(error));
    }
  }

  /// Only the photos' paths go to the server.
  @override
  Future<Result<Message>> sendMessage({
    required String chatId,
    required String text,
    List<String> imagePaths = const [],
    String? postId,
  }) => _storeMessage(
    chatId,
    _api.post('/api/chats/$chatId/messages', {
      'text': text,
      'postId': postId,
      'imageRefs': imagePaths,
    }),
  );

  /// Sends the photos of your latest message along, so the friend can see
  /// them. The server doesn't keep them.
  @override
  Future<Result<Message>> getReply(String chatId) async {
    final path = '/api/chats/$chatId/reply';
    final photos = await _latestPhotos(chatId);
    return _storeMessage(
      chatId,
      photos.isEmpty ? _api.post(path) : _api.postImages(path, photos),
    );
  }

  @override
  Future<Result<List<Photo>>> getPhotos(int page) async {
    return switch (await _photoLibraryService.getPhotos(page)) {
      Ok(:final value) => Result.ok([
        for (final photo in value)
          Photo(id: photo.id, thumbnail: photo.thumbnail),
      ]),
      Error(:final error) => Result.error(
        error is PlatformException && error.code == 'photo_access_denied'
            ? const PhotoAccessDeniedException()
            : error,
      ),
    };
  }

  @override
  Future<Result<List<String>>> getImagePaths(List<String> ids) =>
      _photoLibraryService.getImagePaths(ids);

  @override
  Future<Result<void>> openPhotoSettings() =>
      _photoLibraryService.openSettings();

  @override
  bool get isCallOnline => _voiceCallService.isConnected;

  /// Asks for the microphone, gets a call pass from the server, then connects
  /// to ElevenLabs as this friend.
  @override
  Future<Result<void>> startCall(String chatId) async {
    if (!await _voiceCallService.requestMicrophone()) {
      return const Result.error(MicrophoneDeniedException());
    }
    switch (await _api.post('/api/chats/$chatId/call')) {
      case Ok(
        value: {
          'conversationToken': final String conversationToken,
          'prompt': final String prompt,
          'firstMessage': final String firstMessage,
          'voiceId': final String voiceId,
        },
      ):
        return _voiceCallService.start(
          conversationToken: conversationToken,
          prompt: prompt,
          firstMessage: firstMessage,
          voiceId: voiceId,
        );
      case Ok():
        return const Result.error(FormatException('Unexpected call pass'));
      case Error(:final error):
        return Result.error(_mapError(error));
    }
  }

  /// Hangs up and saves the call record on the server.
  @override
  Future<Result<Message>> endCall({
    required String chatId,
    required Duration duration,
  }) async {
    await _voiceCallService.end();
    return _storeMessage(
      chatId,
      _api.post('/api/chats/$chatId/calls', {
        'durationSeconds': duration.inSeconds,
      }),
    );
  }

  /// Your latest message's photos, shrunk for upload. A photo that can't be
  /// read, e.g. because it was deleted from the phone, is left out.
  Future<List<Uint8List>> _latestPhotos(String chatId) async {
    final latest = _messages[chatId]?.lastOrNull;
    if (latest == null || !latest.isFromYou) return const [];
    return [
      for (final path in latest.imagePaths)
        if (await _imageCompressService.jpeg(path) case Ok(:final value)) value,
    ];
  }

  Future<Result<Chat>> _storeChat(Future<Result<Object?>> request) async {
    switch (await request) {
      case Ok(:final value):
        final chat = _parseChat(value);
        if (chat == null) {
          return const Result.error(FormatException('Unexpected chat'));
        }
        _chats = {..._chats, chat.id: chat};
        notifyListeners();
        return Result.ok(chat);
      case Error(:final error):
        return Result.error(_mapError(error));
    }
  }

  Future<Result<Message>> _storeMessage(
    String chatId,
    Future<Result<Object?>> request,
  ) async {
    switch (await request) {
      case Ok(:final value):
        final message = _parseMessage(value);
        if (message == null) {
          return const Result.error(FormatException('Unexpected message'));
        }
        _addMessage(chatId, message);
        return Result.ok(message);
      case Error(:final error):
        return Result.error(_mapError(error));
    }
  }

  /// Appends to a loaded conversation and moves its chat to the top. A new
  /// friend message counts as unread until the chat is marked read.
  void _addMessage(String chatId, Message message) {
    if (_messages[chatId] case final messages?) {
      _messages = {
        ..._messages,
        chatId: List.unmodifiable([...messages, message]),
      };
    }
    _updateChat(
      chatId,
      (chat) => _summary(
        chat,
        last: message,
        unreadCount: message.isFromYou ? null : chat.unreadCount + 1,
      ),
    );
  }

  void _updateChat(String chatId, Chat Function(Chat chat) change) {
    if (_chats[chatId] case final chat?) {
      _chats = {..._chats, chatId: change(chat)};
    }
    notifyListeners();
  }

  List<Chat> _sorted() => List.unmodifiable(
    _chats.values.toList()
      ..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt)),
  );

  Chat _summary(Chat chat, {Message? last, int? unreadCount}) => Chat(
    id: chat.id,
    friendName: chat.friendName,
    portraitAsset: chat.portraitAsset,
    friendVoice: chat.friendVoice,
    lastMessage: last == null ? chat.lastMessage : _preview(last),
    lastMessageAt: last?.sentAt ?? chat.lastMessageAt,
    unreadCount: unreadCount ?? chat.unreadCount,
  );

  /// Null when malformed, or when the app has no portrait for the friend.
  Chat? _parseChat(Object? json) {
    if (json case {
      'id': final String id,
      'friendName': final String friendName,
      'friendVoice': final String friendVoice,
      'lastMessage': final Object? lastMessage,
      'unreadCount': final int unreadCount,
    }) {
      final portraitAsset = _portraitAssets[id];
      final last = _parseMessage(lastMessage);
      if (portraitAsset == null || last == null) return null;
      return Chat(
        id: id,
        friendName: friendName,
        portraitAsset: portraitAsset,
        friendVoice: friendVoice,
        lastMessage: _preview(last),
        lastMessageAt: last.sentAt,
        unreadCount: unreadCount,
      );
    }
    return null;
  }

  Message? _parseMessage(Object? json) {
    if (json case {
      'id': final String id,
      'text': final String text,
      'sentAt': final String sentAt,
      'isFromYou': final bool isFromYou,
      'postId': final String? postId,
      'imageRefs': final List<Object?> imageRefs,
      'callDurationSeconds': final int? callDurationSeconds,
    }) {
      final at = DateTime.tryParse(sentAt);
      if (at == null) return null;
      return Message(
        id: id,
        text: text,
        sentAt: at.toLocal(),
        isFromYou: isFromYou,
        imagePaths: List.unmodifiable(imageRefs.whereType<String>()),
        postId: postId,
        callDuration: callDurationSeconds == null
            ? null
            : Duration(seconds: callDurationSeconds),
      );
    }
    return null;
  }

  /// The inbox line for a message.
  static String _preview(Message message) => message.text.isNotEmpty
      ? message.text
      : message.callDuration != null
      ? 'Voice call'
      : message.imagePaths.isNotEmpty
      ? 'Shared a photo'
      : 'Replied to a post';

  static Exception _mapError(Exception error) => switch (error) {
    ApiException(code: 'chat_not_found') => const ChatNotFoundException(),
    http.ClientException() => const OfflineException(),
    _ => error,
  };
}
