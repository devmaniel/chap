import '../post/post.dart';

/// An AI character you can meet on Discover.
class Character {
  const Character({
    required this.id,
    required this.name,
    required this.portraitAsset,
    required this.tagline,
    required this.bio,
    required this.interests,
    required this.home,
    required this.postCount,
    required this.friendIds,
    required this.firstHello,
    required this.voice,
    required this.profilePicture,
    this.isFriend = false,
  });

  final String id;
  final String name;
  final String portraitAsset;

  /// Short line on the Discover card.
  final String tagline;

  /// Longer line under the name on the profile.
  final String bio;
  final List<String> interests;

  /// Where they live, e.g. "Old town".
  final String home;
  final int postCount;

  /// Other characters they are friends with.
  final List<String> friendIds;
  final String firstHello;

  /// How they sound, e.g. "Warm & gentle".
  final String voice;
  final Post profilePicture;

  /// Whether they are your friend.
  final bool isFriend;

  Character copyWith({bool? isFriend, Post? profilePicture}) => Character(
    id: id,
    name: name,
    portraitAsset: portraitAsset,
    tagline: tagline,
    bio: bio,
    interests: interests,
    home: home,
    postCount: postCount,
    friendIds: friendIds,
    firstHello: firstHello,
    voice: voice,
    profilePicture: profilePicture ?? this.profilePicture,
    isFriend: isFriend ?? this.isFriend,
  );
}
