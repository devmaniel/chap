import 'package:flutter/foundation.dart';

import '../../../data/repositories/character/character_repository.dart';
import '../../../domain/models/character/character.dart';
import '../../../domain/models/post/post.dart';
import '../../../utils/command.dart';

/// One post full screen: its photos, or the profile picture.
class PhotoViewerViewModel {
  PhotoViewerViewModel({
    required this.characterId,
    required this.postId,
    required this.initialIndex,
    required CharacterRepository characterRepository,
  }) : _characterRepository = characterRepository {
    toggleLike = Command0(() {
      final isLiked = post?.isLiked ?? false;
      return _characterRepository.setLiked(postId, isLiked: !isLiked);
    });
  }

  final String characterId;
  final String postId;
  final int initialIndex;
  final CharacterRepository _characterRepository;

  late final Command0<void> toggleLike;

  /// Fires when the post's likes change.
  Listenable get changes => _characterRepository;

  Character? get character => _characterRepository.cachedCharacter(characterId);

  Post? get post => _characterRepository.cachedPost(postId);
}
