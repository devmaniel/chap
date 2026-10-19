import '../../../domain/models/character/character.dart';
import '../../../domain/models/post/post.dart';
import '../../../utils/result.dart';
import 'character_repository.dart';

/// In-memory characters for building the app before the server exists.
class CharacterRepositoryLocal extends CharacterRepository {
  CharacterRepositoryLocal({
    this.latency = const Duration(milliseconds: 600),
    List<Character> characters = const [],
    Map<String, List<Post>> posts = const {},
    List<Exception> loadFailures = const [],
  }) : _characters = characters,
       _posts = posts,
       _loadFailures = [...loadFailures];

  /// Simulated round trip, so loading states are visible.
  final Duration latency;

  List<Character> _characters;
  Map<String, List<Post>> _posts;
  bool _isLoaded = false;
  final List<Exception> _loadFailures;

  @override
  List<Character>? get cachedCharacters =>
      _isLoaded ? List.unmodifiable(_characters) : null;

  @override
  Character? cachedCharacter(String characterId) => _isLoaded
      ? _characters.where((c) => c.id == characterId).firstOrNull
      : null;

  @override
  List<Post>? cachedPosts(String characterId) =>
      _isLoaded ? List.unmodifiable(_posts[characterId] ?? const []) : null;

  @override
  Post? cachedPost(String postId) {
    if (!_isLoaded) return null;
    return [
      for (final character in _characters) character.profilePicture,
      for (final posts in _posts.values) ...posts,
    ].where((post) => post.id == postId).firstOrNull;
  }

  @override
  Future<Result<List<Character>>> getCharacters() async {
    await Future<void>.delayed(latency);
    if (_loadFailures.isNotEmpty) {
      return Result.error(_loadFailures.removeAt(0));
    }
    _isLoaded = true;
    notifyListeners();
    return Result.ok(List.unmodifiable(_characters));
  }

  @override
  Future<Result<void>> setFriend(
    String characterId, {
    required bool isFriend,
  }) async {
    await Future<void>.delayed(latency);
    if (!_characters.any((c) => c.id == characterId)) {
      return const Result.error(CharacterNotFoundException());
    }
    _characters = [
      for (final c in _characters)
        c.id == characterId ? c.copyWith(isFriend: isFriend) : c,
    ];
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> setLiked(String postId, {required bool isLiked}) async {
    Post like(Post post) =>
        post.id == postId ? post.withLike(isLiked: isLiked) : post;
    _characters = [
      for (final c in _characters)
        c.copyWith(profilePicture: like(c.profilePicture)),
    ];
    _posts = {
      for (final entry in _posts.entries)
        entry.key: [for (final post in entry.value) like(post)],
    };
    notifyListeners();
    return const Result.ok(null);
  }
}
