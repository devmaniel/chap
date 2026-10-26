import 'package:http/http.dart' as http;

import '../../../domain/models/character/character.dart';
import '../../../domain/models/post/post.dart';
import '../../../utils/result.dart';
import '../../services/api_service.dart';
import '../auth/auth_repository.dart';
import 'character_repository.dart';

/// What the app ships for a character that the server doesn't own yet.
typedef BundledCharacter = ({
  String portraitAsset,
  int postCount,
  List<String> friendIds,
  Post profilePicture,
});

/// Profiles and friend status from the Chap server, merged with the portrait,
/// posts and friend circle the app bundles. Likes stay on the device.
class CharacterRepositoryRemote extends CharacterRepository {
  CharacterRepositoryRemote({
    required ApiService apiService,
    required Map<String, BundledCharacter> bundled,
    Map<String, List<Post>> posts = const {},
  }) : _api = apiService,
       _bundled = bundled,
       _posts = posts;

  final ApiService _api;

  /// Keyed by character id, in the order Discover shows them.
  final Map<String, BundledCharacter> _bundled;
  Map<String, List<Post>> _posts;
  List<Character>? _characters;

  @override
  List<Character>? get cachedCharacters => _characters;

  @override
  Character? cachedCharacter(String characterId) =>
      _characters?.where((c) => c.id == characterId).firstOrNull;

  @override
  List<Post>? cachedPosts(String characterId) => _characters == null
      ? null
      : List.unmodifiable(_posts[characterId] ?? const []);

  @override
  Post? cachedPost(String postId) {
    final characters = _characters;
    if (characters == null) return null;
    return [
      for (final character in characters) character.profilePicture,
      for (final posts in _posts.values) ...posts,
    ].where((post) => post.id == postId).firstOrNull;
  }

  @override
  Future<Result<List<Character>>> getCharacters() async {
    switch (await _api.get('/api/characters')) {
      case Ok(value: final List<Object?> items):
        final fromServer = {
          for (final character in items.map(_parse).nonNulls)
            character.id: character,
        };
        final characters = List<Character>.unmodifiable([
          for (final id in _bundled.keys) ?fromServer[id],
        ]);
        _characters = characters;
        notifyListeners();
        return Result.ok(characters);
      case Ok():
        return const Result.error(FormatException('Expected a list'));
      case Error(:final error):
        return Result.error(_mapError(error));
    }
  }

  @override
  Future<Result<void>> setFriend(
    String characterId, {
    required bool isFriend,
  }) async {
    final path = '/api/friends/$characterId';
    switch (isFriend ? await _api.put(path) : await _api.delete(path)) {
      case Ok():
        _update(
          (c) => c.id == characterId ? c.copyWith(isFriend: isFriend) : c,
        );
        return const Result.ok(null);
      case Error(:final error):
        return Result.error(_mapError(error));
    }
  }

  @override
  Future<Result<void>> setLiked(String postId, {required bool isLiked}) async {
    Post like(Post post) =>
        post.id == postId ? post.withLike(isLiked: isLiked) : post;
    _posts = {
      for (final entry in _posts.entries)
        entry.key: [for (final post in entry.value) like(post)],
    };
    _update((c) => c.copyWith(profilePicture: like(c.profilePicture)));
    return const Result.ok(null);
  }

  void _update(Character Function(Character character) change) {
    final characters = _characters;
    if (characters != null) {
      _characters = List.unmodifiable(characters.map(change));
    }
    notifyListeners();
  }

  /// One server entry plus its bundled parts. Null when malformed, or when the
  /// app has no portrait for that character yet.
  Character? _parse(Object? json) {
    if (json case {
      'id': final String id,
      'name': final String name,
      'tagline': final String tagline,
      'bio': final String bio,
      'interests': final List<Object?> interests,
      'home': final String home,
      'voice': final String voice,
      'firstHello': final String firstHello,
      'isFriend': final bool isFriend,
    }) {
      final bundled = _bundled[id];
      if (bundled == null) return null;
      return Character(
        id: id,
        name: name,
        portraitAsset: bundled.portraitAsset,
        tagline: tagline,
        bio: bio,
        interests: List.unmodifiable(interests.whereType<String>()),
        home: home,
        postCount: bundled.postCount,
        friendIds: bundled.friendIds,
        firstHello: firstHello,
        voice: voice,
        // Keeps a like made before this reload.
        profilePicture:
            cachedCharacter(id)?.profilePicture ?? bundled.profilePicture,
        isFriend: isFriend,
      );
    }
    return null;
  }

  static Exception _mapError(Exception error) => switch (error) {
    ApiException(code: 'character_not_found') =>
      const CharacterNotFoundException(),
    http.ClientException() => const OfflineException(),
    _ => error,
  };
}
