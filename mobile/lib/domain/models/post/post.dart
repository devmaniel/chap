/// How a photo is framed: its real shape, shown as-is in the viewer.
enum PhotoShape { landscape, portrait, wide }

/// Sample scenes until characters post real pictures.
enum PhotoScene { sunset, sea, mint, peach, dusk, forest }

class PostPhoto {
  const PostPhoto({
    required this.scene,
    required this.shape,
    required this.description,
  });

  final PhotoScene scene;
  final PhotoShape shape;

  /// Read aloud in place of the picture, e.g. "calm sea".
  final String description;
}

/// Something a character shared on their timeline. A post with no photos
/// and no [place] can also stand for their profile picture.
class Post {
  const Post({
    required this.id,
    required this.characterId,
    required this.text,
    required this.postedAt,
    required this.likeCount,
    this.place,
    this.photos = const [],
    this.isLiked = false,
  });

  final String id;
  final String characterId;
  final String text;
  final DateTime postedAt;
  final String? place;
  final List<PostPhoto> photos;

  /// Includes your own like.
  final int likeCount;
  final bool isLiked;

  /// The same post with your like added or taken back.
  Post withLike({required bool isLiked}) {
    if (isLiked == this.isLiked) return this;
    return Post(
      id: id,
      characterId: characterId,
      text: text,
      postedAt: postedAt,
      place: place,
      photos: photos,
      likeCount: likeCount + (isLiked ? 1 : -1),
      isLiked: isLiked,
    );
  }
}
