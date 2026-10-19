import 'package:flutter/foundation.dart';

import '../../../domain/models/character/character.dart';
import '../../../domain/models/post/post.dart';
import '../../../utils/result.dart';

abstract class CharacterRepository extends ChangeNotifier {
  List<Character>? get cachedCharacters;
  Character? cachedCharacter(String characterId);

  /// The character's timeline, newest first.
  List<Post>? cachedPosts(String characterId);

  /// A timeline post or a profile picture.
  Post? cachedPost(String postId);

  Future<Result<List<Character>>> getCharacters();

  Future<Result<void>> setFriend(String characterId, {required bool isFriend});

  Future<Result<void>> setLiked(String postId, {required bool isLiked});
}

final class CharacterNotFoundException implements Exception {
  const CharacterNotFoundException();
}
