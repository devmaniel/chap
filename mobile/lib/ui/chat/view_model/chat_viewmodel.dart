import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../data/repositories/chat/chat_repository.dart';
import '../../../domain/models/chat/chat.dart';
import '../../../domain/models/message/message.dart';
import '../../../domain/models/photo/photo.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

enum PendingStatus { sending, waitingForConnection, failed }

class ChatViewModel extends ChangeNotifier {
  ChatViewModel({
    required String chatId,
    required ChatRepository chatRepository,
    this.retryDelay = const Duration(seconds: 3),
  }) : _chatId = chatId,
       _chatRepository = chatRepository {
    load = Command0(_load);
    send = Command0(_send);
    reply = Command0(_reply);
    loadPhotos = Command0(_loadPhotos);
    attachImages = Command0(_attachImages);
    photoSettings = Command0(_chatRepository.openPhotoSettings);
    for (final command in _commands) {
      command.addListener(_changed);
    }
    _chat = _chatRepository.cachedChat(_chatId);
    _messages = _chatRepository.cachedMessages(_chatId) ?? const [];
    if (_chat == null) load.execute();
  }

  final String _chatId;
  final ChatRepository _chatRepository;
  final Duration retryDelay;
  late final Command0<void> load;
  late final Command0<void> send;
  late final Command0<void> reply;
  late final Command0<void> loadPhotos;
  late final Command0<void> attachImages;
  late final Command0<void> photoSettings;
  List<Command0<void>> get _commands => [
    load,
    send,
    reply,
    loadPhotos,
    attachImages,
    photoSettings,
  ];

  Chat? _chat;
  List<Message> _messages = const [];
  String _draft = '';
  List<String> _draftImages = const [];
  Message? _pending;
  bool _isOffline = false;
  bool _disposed = false;
  String? _revealingMessageId;
  Timer? _retryTimer;
  List<Photo> _photos = const [];
  List<String> _selectedPhotos = [];
  int _photoPage = 0;
  bool _hasMorePhotos = true;
  bool _isVisible = true;

  double scrollOffset = 0;
  String get draft => _draft;

  void setVisible(bool value) {
    _isVisible = value;
    if (!value) _revealingMessageId = null;
  }

  Chat? get chat => _chat;
  List<Message> get messages => List.unmodifiable(_messages);
  List<String> get draftImages => List.unmodifiable(_draftImages);
  Message? get pending => _pending;
  bool get isOffline => _isOffline;
  String? get revealingMessageId => _revealingMessageId;
  List<Photo> get photos => List.unmodifiable(_photos);
  List<String> get selectedPhotos => List.unmodifiable(_selectedPhotos);
  bool get hasMorePhotos => _hasMorePhotos;
  bool get photoAccessDenied => switch (loadPhotos.result) {
    Error(error: PhotoAccessDeniedException()) => true,
    _ => false,
  };
  bool get canCompose =>
      _chat != null &&
      !load.running &&
      _pending == null &&
      !send.running &&
      !reply.running &&
      !reply.error &&
      _revealingMessageId == null &&
      !attachImages.running;
  bool get canSend =>
      canCompose && (_draft.trim().isNotEmpty || _draftImages.isNotEmpty);

  PendingStatus? get pendingStatus {
    if (_pending == null) return null;
    if (send.running) return PendingStatus.sending;
    if (_isOffline) return PendingStatus.waitingForConnection;
    return send.error ? PendingStatus.failed : PendingStatus.sending;
  }

  void setDraft(String value) {
    if (_draft == value) return;
    _draft = value;
    _changed();
  }

  void removeImage(String path) {
    _draftImages = _draftImages.where((image) => image != path).toList();
    _changed();
  }

  void openGallery() {
    _selectedPhotos = [];
    attachImages.clearResult();
    if (_photos.isEmpty || loadPhotos.error) loadPhotos.execute();
    _changed();
  }

  void togglePhoto(String id) {
    if (attachImages.running) return;
    _selectedPhotos = _selectedPhotos.contains(id)
        ? _selectedPhotos.where((photo) => photo != id).toList()
        : [..._selectedPhotos, id];
    _changed();
  }

  void submit() {
    if (!canSend) return;
    _pending = Message(
      id: 'pending',
      text: _draft.trim(),
      sentAt: DateTime.now(),
      isFromYou: true,
      imagePaths: _draftImages,
    );
    _draft = '';
    _draftImages = const [];
    send.execute();
  }

  void retry() {
    _retryTimer?.cancel();
    if (_pending != null) send.execute();
  }

  void finishReveal() {
    _revealingMessageId = null;
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    for (final command in _commands) {
      command.removeListener(_changed);
    }
    super.dispose();
  }

  Future<Result<void>> _load() async {
    final (chat, messages) = await (
      _chatRepository.getChat(_chatId),
      _chatRepository.getMessages(_chatId),
    ).wait;
    if (_disposed) return const Result.ok(null);
    switch ((chat, messages)) {
      case (Ok(value: final chat), Ok(value: final messages)):
        _chat = chat;
        _messages = messages;
        return const Result.ok(null);
      case (Error(:final error), _) || (_, Error(:final error)):
        return Result.error(error);
    }
  }

  Future<Result<void>> _send() async {
    final pending = _pending;
    if (pending == null) return const Result.ok(null);
    final result = await _chatRepository.sendMessage(
      chatId: _chatId,
      text: pending.text,
      imagePaths: pending.imagePaths,
    );
    if (_disposed) return const Result.ok(null);
    switch (result) {
      case Ok(:final value):
        _messages = [..._messages, value];
        _pending = null;
        _isOffline = false;
        reply.execute();
        return const Result.ok(null);
      case Error(:final error):
        _waitForConnection(error, send);
        return Result.error(error);
    }
  }

  Future<Result<void>> _reply() async {
    final result = await _chatRepository.getReply(_chatId);
    if (_disposed) return const Result.ok(null);
    switch (result) {
      case Ok(:final value):
        _messages = [..._messages, value];
        _isOffline = false;
        _revealingMessageId = _isVisible ? value.id : null;
        return const Result.ok(null);
      case Error(:final error):
        _waitForConnection(error, reply);
        return Result.error(error);
    }
  }

  void _waitForConnection(Exception error, Command0<void> command) {
    _isOffline = error is OfflineException;
    if (_isOffline) {
      _retryTimer = Timer(retryDelay, () {
        if (!_disposed) command.execute();
      });
    }
  }

  Future<Result<void>> _loadPhotos() async {
    if (!_hasMorePhotos) return const Result.ok(null);
    final result = await _chatRepository.getPhotos(_photoPage);
    if (_disposed) return const Result.ok(null);
    switch (result) {
      case Ok(:final value):
        _photos = [..._photos, ...value];
        _photoPage++;
        _hasMorePhotos = value.isNotEmpty;
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }

  Future<Result<void>> _attachImages() async {
    if (_selectedPhotos.isEmpty) return const Result.ok(null);
    final result = await _chatRepository.getImagePaths(_selectedPhotos);
    if (_disposed) return const Result.ok(null);
    switch (result) {
      case Ok(:final value):
        _draftImages = {..._draftImages, ...value}.toList();
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }
}

String messageTimeLabel(DateTime at) {
  final local = at.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  return '$hour:${local.minute.toString().padLeft(2, '0')}';
}

String messageDayLabel(DateTime at) {
  final local = at.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  return switch (today.difference(day).inDays) {
    0 => 'Today',
    1 => 'Yesterday',
    _ => '${local.month}/${local.day}/${local.year}',
  };
}
