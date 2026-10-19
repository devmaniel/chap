import 'package:flutter/foundation.dart';

import '../../../data/repositories/chat/chat_repository.dart';
import '../../../domain/models/chat/chat.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

class ChatsViewModel extends ChangeNotifier {
  ChatsViewModel({required ChatRepository chatRepository})
    : _chatRepository = chatRepository {
    load = Command0(_load);
    final cached = _chatRepository.cachedChats;
    if (cached != null) {
      _allChats = cached;
    } else {
      load.execute();
    }
    _chatRepository.addListener(_syncChats);
  }

  final ChatRepository _chatRepository;

  late final Command0<void> load;

  List<Chat> _allChats = const [];
  bool _isSearching = false;
  String _query = '';

  bool get isSearching => _isSearching;

  Draft? draftFor(String chatId) => _chatRepository.draftFor(chatId);
  String get query => _query;

  void _syncChats() {
    _allChats = _chatRepository.cachedChats ?? _allChats;
    notifyListeners();
  }

  @override
  void dispose() {
    _chatRepository.removeListener(_syncChats);
    super.dispose();
  }

  /// Every chat until a query is typed, then those whose name or last
  /// message contains it, ignoring case.
  List<Chat> get chats {
    final needle = _query.trim().toLowerCase();
    if (needle.isEmpty) return _allChats;
    return _allChats
        .where(
          (chat) =>
              chat.friendName.toLowerCase().contains(needle) ||
              chat.lastMessage.toLowerCase().contains(needle),
        )
        .toList();
  }

  void openSearch() {
    _isSearching = true;
    notifyListeners();
  }

  /// Closing drops the query, so the full list comes back.
  void closeSearch() {
    _isSearching = false;
    _query = '';
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  Future<Result<void>> _load() async {
    switch (await _chatRepository.getChats()) {
      case Ok(:final value):
        _allChats = value;
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }
}

/// Inbox preview after "Draft:" — photo count, then text, whichever exist.
String draftPreview(Draft draft) {
  final count = draft.imagePaths.length;
  final text = draft.text.trim();
  return [
    if (count > 0) count == 1 ? 'Photo' : '$count photos',
    if (text.isNotEmpty) text,
  ].join(' · ');
}

/// Short time beside a chat: Now, 12m, 3h, Yesterday, then month/day.
String chatTimeLabel(DateTime at, DateTime now) {
  final age = now.difference(at);
  if (age.inMinutes < 1) return 'Now';
  if (age.inHours < 1) return '${age.inMinutes}m';

  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(at.year, at.month, at.day);
  final daysAgo = today.difference(day).inDays;
  if (daysAgo == 0) return '${age.inHours}h';
  if (daysAgo == 1) return 'Yesterday';
  return '${at.month}/${at.day}';
}
