import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_local.dart';
import '../data/repositories/character/character_repository.dart';
import '../data/repositories/character/character_repository_local.dart';
import '../data/repositories/chat/chat_repository.dart';
import '../data/repositories/chat/chat_repository_local.dart';
import '../domain/models/character/character.dart';
import '../domain/models/chat/chat.dart';
import '../domain/models/message/message.dart';
import '../domain/models/post/post.dart';
import '../ui/chat/view_model/chat_viewmodel.dart';
import '../ui/chats/view_model/chats_viewmodel.dart';
import '../ui/discover/view_model/discover_viewmodel.dart';
import '../ui/friends/view_model/friends_viewmodel.dart';
import '../ui/profile/view_model/profile_viewmodel.dart';

/// Swap the local repositories for remote implementations once the server exists.
List<SingleChildWidget> get providers => [
  ChangeNotifierProvider<AuthRepository>(
    create: (_) => AuthRepositoryLocal(
      // Test account. Emails are stored lowercase.
      passwordsByEmail: const {'melco@example.com': 'Password123'},
    ),
  ),
  ChangeNotifierProvider<ChatRepository>(
    create: (_) {
      final now = DateTime.now();
      return ChatRepositoryLocal(
        chats: _sampleChats(now),
        messages: _sampleMessages(now),
        sendFailures: switch (const String.fromEnvironment('CHAT_SCENARIO')) {
          'send-error' => [Exception('Sample send failure')],
          'offline' => [const OfflineException(), const OfflineException()],
          _ => const [],
        },
        replyFailures: switch (const String.fromEnvironment('CHAT_SCENARIO')) {
          'reply-error' => [Exception('Sample reply failure')],
          _ => const [],
        },
        callFailures: switch (const String.fromEnvironment('CHAT_SCENARIO')) {
          'call-error' => [Exception('Sample call failure')],
          _ => const [],
        },
        callDrop: switch (const String.fromEnvironment('CHAT_SCENARIO')) {
          'call-offline' => (
            after: const Duration(seconds: 5),
            length: const Duration(seconds: 6),
          ),
          _ => null,
        },
      );
    },
  ),
  ChangeNotifierProvider<CharacterRepository>(
    create: (_) {
      final now = DateTime.now();
      return CharacterRepositoryLocal(
        characters: _sampleCharacters(now),
        posts: _samplePosts(now),
        loadFailures: switch (const String.fromEnvironment(
          'CHARACTER_SCENARIO',
        )) {
          'load-error' => [Exception('Sample load failure')],
          _ => const [],
        },
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

List<Chat> _sampleChats(DateTime now) => [
  Chat(
    id: 'mina',
    friendName: 'Mina',
    portraitAsset: 'assets/images/portrait_mina.png',
    friendVoice: 'Warm & gentle',
    lastMessage: 'I finally found that little bookshop.',
    lastMessageAt: now.subtract(const Duration(minutes: 12)),
    unreadCount: 2,
  ),
  Chat(
    id: 'kai',
    friendName: 'Kai',
    portraitAsset: 'assets/images/portrait_kai.png',
    friendVoice: 'Calm & relaxed',
    lastMessage: 'One song for a rainy walk. Your pick?',
    lastMessageAt: now.subtract(const Duration(hours: 1)),
    unreadCount: 1,
  ),
  Chat(
    id: 'sol',
    friendName: 'Sol',
    portraitAsset: 'assets/images/portrait_sol.png',
    friendVoice: 'Bright & playful',
    lastMessage: 'Tell me how your sketch turned out.',
    lastMessageAt: now.subtract(const Duration(days: 1)),
    unreadCount: 0,
  ),
];

Map<String, List<Message>> _sampleMessages(DateTime now) {
  Message message(String id, String text, Duration ago, {bool you = false}) =>
      Message(id: id, text: text, sentAt: now.subtract(ago), isFromYou: you);
  const minaAgo = Duration(minutes: 12);
  return {
    'mina': [
      message(
        'mina-1',
        'I needed a little break from the usual today.',
        minaAgo,
        you: true,
      ),
      message(
        'mina-2',
        'I took the long way home and found a tiny bookshop tucked between '
            'two cafés. The best kind of detour.',
        minaAgo,
      ),
      message(
        'mina-3',
        'What about you? Find anything worth a second look?',
        minaAgo,
      ),
    ],
    'kai': [
      message(
        'kai-1',
        'One song for a rainy walk. Your pick?',
        const Duration(hours: 1),
      ),
    ],
    'sol': [
      message(
        'sol-1',
        'Tell me how your sketch turned out.',
        const Duration(days: 1),
      ),
    ],
  };
}

List<Character> _sampleCharacters(DateTime now) {
  Post picture(String id, String caption, int likes) => Post(
    id: '$id-picture',
    characterId: id,
    text: caption,
    postedAt: now.subtract(const Duration(days: 14)),
    likeCount: likes,
  );
  return [
    Character(
      id: 'mina',
      name: 'Mina',
      portraitAsset: 'assets/images/portrait_mina.png',
      tagline: 'A curious soul who finds little stories in everyday things.',
      bio:
          'A curious soul who finds little stories in everyday things. '
          'Usually carrying a sketchbook.',
      interests: const ['Art', 'Coffee', 'Small talk'],
      home: 'Old town',
      postCount: 24,
      friendIds: const ['kai', 'sol'],
      firstHello:
          'I took the long way home and found a tiny bookshop tucked between '
          'two cafés. The best kind of detour.',
      voice: 'Warm & gentle',
      profilePicture: picture('mina', 'New sketchbook, new me.', 87),
      isFriend: true,
    ),
    Character(
      id: 'kai',
      name: 'Kai',
      portraitAsset: 'assets/images/portrait_kai.png',
      tagline: 'Your easygoing music nerd.',
      bio: 'Your easygoing music nerd. Always has a song for the mood.',
      interests: const ['Music', 'Ideas', 'Small talk'],
      home: 'Record shop',
      postCount: 0,
      friendIds: const ['mina'],
      firstHello: 'One song for a rainy walk. Your pick?',
      voice: 'Calm & relaxed',
      profilePicture: picture('kai', 'Headphones on, world off.', 64),
      isFriend: true,
    ),
    Character(
      id: 'sol',
      name: 'Sol',
      portraitAsset: 'assets/images/portrait_sol.png',
      tagline:
          'A thoughtful book lover with a soft spot for big questions and '
          'wonderfully ordinary days..',
      bio:
          'Hums while cooking, collects old records, and always has a song '
          'for the mood.',
      interests: const ['Books', 'Ideas', 'Art'],
      home: 'Harbor flat',
      postCount: 0,
      friendIds: const ['lumi'],
      firstHello: 'Tell me how your sketch turned out.',
      voice: 'Bright & playful',
      profilePicture: picture('sol', 'Harbor light, best light.', 41),
    ),
    Character(
      id: 'lumi',
      name: 'Lumi',
      portraitAsset: 'assets/images/portrait_lumi.png',
      tagline:
          'An imaginative storyteller who turns “what if” into a tiny '
          'adventure.',
      bio:
          'An imaginative storyteller who turns “what if” into a tiny '
          'adventure. Bring your wildest ideas.',
      interests: const ['Stories', 'Art', 'Ideas'],
      home: 'Moon garden',
      postCount: 31,
      friendIds: const ['mina', 'kai'],
      firstHello: 'What if the moon kept a diary? I think I found a page.',
      voice: 'Soft & dreamy',
      profilePicture: picture('lumi', 'Moonlight suits me.', 112),
    ),
  ];
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
    'lumi': [
      Post(
        id: 'lumi-1',
        characterId: 'lumi',
        text:
            'A door appeared in the garden this morning. I have not opened it '
            'yet. Should I?',
        postedAt: ago(const Duration(hours: 1)),
        place: 'Moon garden',
        photos: const [
          PostPhoto(
            scene: PhotoScene.dusk,
            shape: PhotoShape.portrait,
            description: 'purple dusk over a garden',
          ),
        ],
        likeCount: 210,
      ),
    ],
  };
}
