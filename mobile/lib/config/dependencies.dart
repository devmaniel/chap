import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_remote.dart';
import '../data/repositories/character/character_repository.dart';
import '../data/repositories/character/character_repository_remote.dart';
import '../data/repositories/chat/chat_repository.dart';
import '../data/repositories/chat/chat_repository_remote.dart';
import '../data/services/api_service.dart';
import '../domain/models/post/post.dart';
import '../ui/chat/view_model/chat_viewmodel.dart';
import '../ui/chats/view_model/chats_viewmodel.dart';
import '../ui/discover/view_model/discover_viewmodel.dart';
import '../ui/friends/view_model/friends_viewmodel.dart';
import '../ui/profile/view_model/profile_viewmodel.dart';

/// The app-wide services and repositories, backed by the Chap server.
List<SingleChildWidget> get providers => [
  Provider<ApiService>(create: (_) => ApiService()),
  ChangeNotifierProvider<AuthRepository>(
    create: (context) => AuthRepositoryRemote(apiService: context.read()),
  ),
  ChangeNotifierProvider<ChatRepository>(
    create: (context) => ChatRepositoryRemote(
      apiService: context.read(),
      portraitAssets: {
        for (final MapEntry(:key, :value) in _bundledCharacters(
          DateTime.now(),
        ).entries)
          key: value.portraitAsset,
      },
    ),
  ),
  ChangeNotifierProvider<CharacterRepository>(
    create: (context) {
      final now = DateTime.now();
      return CharacterRepositoryRemote(
        apiService: context.read(),
        bundled: _bundledCharacters(now),
        posts: _samplePosts(now),
      );
    },
  ),
  ...chatViewModelProviders,
  ...discoverViewModelProviders,
];

/// These view models live for the app session, so the filter and profile
/// tabs survive route rebuilds.
List<SingleChildWidget> get discoverViewModelProviders => [
  ChangeNotifierProvider<DiscoverViewModel>(
    create: (context) => DiscoverViewModel(characterRepository: context.read()),
  ),
  ChangeNotifierProvider<FriendsViewModel>(
    create: (context) => FriendsViewModel(characterRepository: context.read()),
  ),
  Provider<Map<String, ProfileViewModel>>(
    create: (_) => {},
    dispose: (_, models) {
      for (final model in models.values) {
        model.dispose();
      }
    },
  ),
];

/// These view models live for the app session, independently of route rebuilds.
List<SingleChildWidget> get chatViewModelProviders => [
  ChangeNotifierProvider<ChatsViewModel>(
    create: (context) => ChatsViewModel(chatRepository: context.read()),
  ),
  Provider<Map<String, ChatViewModel>>(
    create: (_) => {},
    dispose: (_, models) {
      for (final model in models.values) {
        model.dispose();
      }
    },
  ),
];

/// What the app ships for each character, in Discover order. Profiles and
/// friend status come from the server.
Map<String, BundledCharacter> _bundledCharacters(DateTime now) {
  Post picture(String id, String caption, int likes) => Post(
    id: '$id-picture',
    characterId: id,
    text: caption,
    postedAt: now.subtract(const Duration(days: 14)),
    likeCount: likes,
  );
  return {
    'mina': (
      portraitAsset: 'assets/images/portrait_mina.png',
      postCount: 24,
      friendIds: const ['bo', 'pip'],
      profilePicture: picture('mina', 'New hat, new me.', 87),
    ),
    'bo': (
      portraitAsset: 'assets/images/portrait_bo.png',
      postCount: 0,
      friendIds: const ['mina', 'momo'],
      profilePicture: picture('bo', 'Apron on, grill hot.', 58),
    ),
    'pip': (
      portraitAsset: 'assets/images/portrait_pip.png',
      postCount: 0,
      friendIds: const ['vera'],
      profilePicture: picture('pip', 'Third coffee. Still studying.', 41),
    ),
    'vera': (
      portraitAsset: 'assets/images/portrait_vera.png',
      postCount: 0,
      friendIds: const ['mina', 'bo'],
      profilePicture: picture('vera', 'New role, same coffee.', 112),
    ),
    'momo': (
      portraitAsset: 'assets/images/portrait_momo.png',
      postCount: 0,
      friendIds: const ['bo'],
      profilePicture: picture('momo', 'Found a new leaf. Wearing it.', 73),
    ),
    'ziggy': (
      portraitAsset: 'assets/images/portrait_ziggy.png',
      postCount: 0,
      friendIds: const ['mina'],
      profilePicture: picture('ziggy', 'New hair, who dis.', 205),
    ),
  };
}

Map<String, List<Post>> _samplePosts(DateTime now) {
  DateTime ago(Duration duration) => now.subtract(duration);
  return {
    'mina': [
      Post(
        id: 'mina-1',
        characterId: 'mina',
        text:
            'Took the long way home and found a tiny bookshop tucked between '
            'two cafés. The best kind of detour.',
        postedAt: ago(const Duration(hours: 2)),
        place: 'Old town',
        photos: const [
          PostPhoto(
            scene: PhotoScene.sunset,
            shape: PhotoShape.landscape,
            description: 'warm evening street',
          ),
        ],
        likeCount: 128,
      ),
      Post(
        id: 'mina-2',
        characterId: 'mina',
        text:
            'Sketchbook morning by the water. The gulls refused to sit still.',
        postedAt: ago(const Duration(days: 1, hours: 3)),
        place: 'Seaside',
        photos: const [
          PostPhoto(
            scene: PhotoScene.sea,
            shape: PhotoShape.portrait,
            description: 'calm sea',
          ),
          PostPhoto(
            scene: PhotoScene.mint,
            shape: PhotoShape.portrait,
            description: 'pale morning sky',
          ),
        ],
        likeCount: 96,
      ),
      Post(
        id: 'mina-3',
        characterId: 'mina',
        text: 'Weekend at the coast. Five photos, zero regrets.',
        postedAt: ago(const Duration(days: 3, hours: 2)),
        place: 'Coast',
        photos: const [
          PostPhoto(
            scene: PhotoScene.sea,
            shape: PhotoShape.wide,
            description: 'wide view of the coast',
          ),
          PostPhoto(
            scene: PhotoScene.peach,
            shape: PhotoShape.portrait,
            description: 'beach café',
          ),
          PostPhoto(
            scene: PhotoScene.forest,
            shape: PhotoShape.portrait,
            description: 'cliff path',
          ),
          PostPhoto(
            scene: PhotoScene.sunset,
            shape: PhotoShape.landscape,
            description: 'sunset over the water',
          ),
          PostPhoto(
            scene: PhotoScene.mint,
            shape: PhotoShape.landscape,
            description: 'tide pools',
          ),
        ],
        likeCount: 143,
      ),
      Post(
        id: 'mina-4',
        characterId: 'mina',
        text:
            'Small question for today: what is one thing you noticed on your '
            'walk?',
        postedAt: ago(const Duration(days: 4, hours: 2)),
        likeCount: 54,
      ),
    ],
  };
}
