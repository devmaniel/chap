import 'package:flutter/foundation.dart';

import '../../../data/repositories/character/character_repository.dart';
import '../../../data/repositories/chat/chat_repository.dart';
import '../../../domain/models/character/character.dart';
import '../../../domain/models/chat/chat.dart';
import '../../../domain/models/post/post.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

enum ProfileTab { posts, photos, about }

/// Where a photo on the Photos tab opens: its post, at that photo.
typedef PhotoRef = ({Post post, int index});

class ProfileViewModel extends ChangeNotifier {
  ProfileViewModel({
    required this.characterId,
    required CharacterRepository characterRepository,
    required ChatRepository chatRepository,
  }) : _characterRepository = characterRepository,
       _chatRepository = chatRepository {
    load = Command0(_load);
    addFriend = Command0(_addFriend);
    removeFriend = Command0(
      () => _characterRepository.setFriend(characterId, isFriend: false),
    );
    toggleLike = Command1(
      (post) => _characterRepository.setLiked(post.id, isLiked: !post.isLiked),
    );
    if (_characterRepository.cachedCharacters == null) load.execute();
  }

  final String characterId;
  final CharacterRepository _characterRepository;
  final ChatRepository _chatRepository;

  late final Command0<void> load;
  late final Command0<void> addFriend;
  late final Command0<void> removeFriend;
  late final Command1<void, Post> toggleLike;

  ProfileTab _tab = ProfileTab.posts;

  /// Fires when the tab, the load or any character changes.
  Listenable get changes => Listenable.merge([
    this,
    load,
    addFriend,
    removeFriend,
    _characterRepository,
  ]);

  ProfileTab get tab => _tab;

  Character? get character => _characterRepository.cachedCharacter(characterId);

  List<Post> get posts =>
      _characterRepository.cachedPosts(characterId) ?? const [];

  /// Their friends among the other characters.
  List<Character> get friends => [
    for (final id in character?.friendIds ?? const <String>[])
      ?_characterRepository.cachedCharacter(id),
  ];

  /// Every picture from their posts, in timeline order.
  List<PhotoRef> get photos => [
    for (final post in posts)
      for (var i = 0; i < post.photos.length; i++) (post: post, index: i),
  ];

  void selectTab(ProfileTab tab) {
    if (tab == _tab) return;
    _tab = tab;
    notifyListeners();
  }

  /// Befriends them and opens a chat with their first hello, so Message
  /// has somewhere to go.
  Future<Result<void>> _addFriend() async {
    final friend = character;
    if (friend == null) return const Result.error(CharacterNotFoundException());
    if (await _characterRepository.setFriend(characterId, isFriend: true)
        case Error(:final error)) {
      return Result.error(error);
    }
    final started = await _chatRepository.startChat(
      Chat(
        id: friend.id,
        friendName: friend.name,
        portraitAsset: friend.portraitAsset,
        friendVoice: friend.voice,
        lastMessage: friend.firstHello,
        lastMessageAt: DateTime.now(),
        unreadCount: 1,
      ),
    );
    return switch (started) {
      Ok() => const Result.ok(null),
      Error(:final error) => Result.error(error),
    };
  }

  Future<Result<void>> _load() async {
    switch (await _characterRepository.getCharacters()) {
      case Ok():
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(error);
    }
  }
}

/// "Friends with Kai", "Friends with Kai and Sol", "Friends with A, B and C".
String friendsLabel(List<String> names) {
  if (names.length < 2) return 'Friends with ${names.join()}';
  return 'Friends with ${names.sublist(0, names.length - 1).join(', ')} '
      'and ${names.last}';
}

/// Age of a post: 12m, 2h, Yesterday, 3 days ago, 2 weeks ago.
String postTimeLabel(DateTime at, DateTime now) {
  final age = now.difference(at);
  if (age.inHours < 1) return '${age.inMinutes}m';
  if (age.inDays < 1) return '${age.inHours}h';
  if (age.inDays == 1) return 'Yesterday';
  if (age.inDays < 7) return '${age.inDays} days ago';
  final weeks = age.inDays ~/ 7;
  return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
}

/// Line under a post's name: "2h · Old town", or for a profile picture
/// "Profile picture · 2 weeks ago".
String postMetaLabel(Post post, DateTime now) {
  final time = postTimeLabel(post.postedAt, now);
  if (post.photos.isEmpty && post.place == null) {
    return 'Profile picture · $time';
  }
  return [time, ?post.place].join(' · ');
}
