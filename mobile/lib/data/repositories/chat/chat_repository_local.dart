import 'dart:async';

import 'package:flutter/services.dart';

import '../../../domain/models/chat/chat.dart';
import '../../../domain/models/message/message.dart';
import '../../../domain/models/photo/photo.dart';
import '../../../utils/result.dart';
import '../../services/photo_library_service.dart';
import 'chat_repository.dart';

/// In-memory chats for building the app before the server exists.
/// Friends answer with canned replies, in turn.
class ChatRepositoryLocal extends ChatRepository {
  ChatRepositoryLocal({
    this.latency = const Duration(milliseconds: 600),
    this.replyDelay = const Duration(seconds: 2),
    List<Chat> chats = const [],
    Map<String, List<Message>> messages = const {},
    PhotoLibraryService? photoLibraryService,
    List<Exception> sendFailures = const [],
    List<Exception> replyFailures = const [],
    this.ringDelay = const Duration(seconds: 3),
    List<Exception> callFailures = const [],
    this.callDrop,
  }) : _chats = chats,
       _messages = messages,
       _photoLibraryService = photoLibraryService ?? PhotoLibraryService(),
       _sendFailures = [...sendFailures],
       _replyFailures = [...replyFailures],
       _callFailures = [...callFailures];

  static const _replies = [
    'I love that. What made you notice it?',
    'Tell me more. How did it feel?',
    'That sounds like a moment worth keeping.',
  ];

  /// Simulated round trip, so loading states are visible.
  final Duration latency;

  /// How long the friend thinks before answering.
  final Duration replyDelay;

  List<Chat> _chats;
  Map<String, List<Message>> _messages;
  int _nextId = 0;
  Map<String, Draft> _drafts = const {};
  final PhotoLibraryService _photoLibraryService;
  final List<Exception> _sendFailures;
  final List<Exception> _replyFailures;

  /// How long a call rings before the friend picks up.
  final Duration ringDelay;

  /// When a picked-up call loses its connection, and for how long.
  final ({Duration after, Duration length})? callDrop;
  final List<Exception> _callFailures;
  bool _isCallOnline = true;
  List<Timer> _callDropTimers = const [];

  @override
  List<Chat> get cachedChats => List.unmodifiable(
    [..._chats]..sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt)),
  );

  @override
  Chat? cachedChat(String chatId) =>
      _chats.where((chat) => chat.id == chatId).firstOrNull;

  @override
  List<Message> cachedMessages(String chatId) =>
      List.unmodifiable(_messages[chatId] ?? const []);

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
  Future<Result<List<Chat>>> getChats() async {
    await Future<void>.delayed(latency);
    return Result.ok(cachedChats);
  }

  @override
  Future<Result<Chat>> getChat(String chatId) async {
    await Future<void>.delayed(latency);
    final chat = cachedChat(chatId);
    if (chat == null) return const Result.error(ChatNotFoundException());
    return Result.ok(chat);
  }

  @override
  Future<Result<Chat>> startChat(Chat chat) async {
    final existing = cachedChat(chat.id);
    if (existing != null) return Result.ok(existing);
    _chats = [..._chats, chat];
    _messages = {
      ..._messages,
      chat.id: [
        Message(
          id: 'local-${_nextId++}',
          text: chat.lastMessage,
          sentAt: chat.lastMessageAt,
          isFromYou: false,
        ),
      ],
    };
    notifyListeners();
    return Result.ok(chat);
  }

  @override
  Future<Result<List<Message>>> getMessages(String chatId) async {
    await Future<void>.delayed(latency);
    return Result.ok(cachedMessages(chatId));
  }

  @override
  Future<Result<Message>> sendMessage({
    required String chatId,
    required String text,
    List<String> imagePaths = const [],
    String? postId,
  }) async {
    await Future<void>.delayed(latency);
    if (_sendFailures.isNotEmpty) {
      return Result.error(_sendFailures.removeAt(0));
    }
    return Result.ok(
      _record(
        chatId,
        text,
        isFromYou: true,
        imagePaths: imagePaths,
        postId: postId,
      ),
    );
  }

  @override
  bool get isCallOnline => _isCallOnline;

  @override
  Future<Result<void>> startCall(String chatId) async {
    await Future<void>.delayed(ringDelay);
    if (_callFailures.isNotEmpty) {
      return Result.error(_callFailures.removeAt(0));
    }
    final drop = callDrop;
    if (drop != null) {
      _callDropTimers = [
        Timer(drop.after, () => _setCallOnline(false)),
        Timer(drop.after + drop.length, () => _setCallOnline(true)),
      ];
    }
    return const Result.ok(null);
  }

  void _setCallOnline(bool isOnline) {
    _isCallOnline = isOnline;
    notifyListeners();
  }

  @override
  Future<Result<Message>> endCall({
    required String chatId,
    required Duration duration,
  }) async {
    for (final timer in _callDropTimers) {
      timer.cancel();
    }
    _isCallOnline = true;
    await Future<void>.delayed(latency);
    return Result.ok(
      _record(chatId, '', isFromYou: true, callDuration: duration),
    );
  }

  @override
  Future<Result<Message>> getReply(String chatId) async {
    await Future<void>.delayed(replyDelay);
    if (_replyFailures.isNotEmpty) {
      return Result.error(_replyFailures.removeAt(0));
    }
    final repliesSoFar = (_messages[chatId] ?? const <Message>[])
        .where((message) => !message.isFromYou)
        .length;
    final latest = _messages[chatId]?.lastOrNull;
    final text = switch (latest) {
      Message(postId: _?) =>
        'I’m so glad that post caught your eye! What did it remind you of?',
      Message(imagePaths: [_, ...]) =>
        'Those colors! What made you want to share this moment?',
      _ => _replies[repliesSoFar % _replies.length],
    };
    return Result.ok(_record(chatId, text, isFromYou: false));
  }

  /// Appends to the conversation and moves its chat to the top of the inbox.
  Message _record(
    String chatId,
    String text, {
    required bool isFromYou,
    List<String> imagePaths = const [],
    String? postId,
    Duration? callDuration,
  }) {
    final message = Message(
      id: 'local-${_nextId++}',
      text: text,
      sentAt: DateTime.now(),
      isFromYou: isFromYou,
      imagePaths: List.unmodifiable(imagePaths),
      postId: postId,
      callDuration: callDuration,
    );
    _messages = {
      ..._messages,
      chatId: [...?_messages[chatId], message],
    };
    _chats = [
      for (final chat in _chats)
        chat.id == chatId
            ? Chat(
                id: chat.id,
                friendName: chat.friendName,
                portraitAsset: chat.portraitAsset,
                friendVoice: chat.friendVoice,
                lastMessage: text.isNotEmpty
                    ? text
                    : callDuration != null
                    ? 'Voice call'
                    : imagePaths.isNotEmpty
                    ? 'Shared a photo'
                    : 'Replied to a post',
                lastMessageAt: message.sentAt,
                unreadCount: chat.unreadCount,
              )
            : chat,
    ];
    notifyListeners();
    return message;
  }
}
