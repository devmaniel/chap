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
    friendVoice: 'Bright & bold',
    lastMessage: 'I finally found that little bookshop.',
    lastMessageAt: now.subtract(const Duration(minutes: 12)),
    unreadCount: 2,
  ),
  Chat(
    id: 'bo',
    friendName: 'Bo',
    portraitAsset: 'assets/images/portrait_bo.png',
    friendVoice: 'Big & cozy',
    lastMessage: 'Saved you a plate. Coming by tonight?',
    lastMessageAt: now.subtract(const Duration(hours: 1)),
    unreadCount: 1,
  ),
  Chat(
    id: 'pip',
    friendName: 'Pip',
    portraitAsset: 'assets/images/portrait_pip.png',
    friendVoice: 'Soft & careful',
    lastMessage: 'Sorry, just saw this! Are we okay?',
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
    'bo': [
      message(
        'bo-1',
        'Saved you a plate. Coming by tonight?',
        const Duration(hours: 1),
      ),
    ],
    'pip': [
      message(
        'pip-1',
        'Sorry, just saw this! Are we okay?',
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
      tagline: 'Unemployed adventurer, always planning the next trip.',
      bio:
          'Unemployed adventurer. Just back from a trip to find himself, '
          'already planning the next one.',
      interests: const ['Travel', 'Food', 'Stories'],
      home: 'On the road',
      postCount: 24,
      friendIds: const ['bo', 'pip'],
      firstHello:
          'I missed my bus, so I hitched a ride to the coast instead. '
          'Best mistake this week.',
      voice: 'Bright & bold',
      profilePicture: picture('mina', 'New hat, new me.', 87),
      isFriend: true,
    ),
    Character(
      id: 'bo',
      name: 'Bo',
      portraitAsset: 'assets/images/portrait_bo.png',
      tagline: 'Runs a little diner and feeds everyone.',
      bio:
          'Runs a little diner and feeds everyone. The friend who shows up '
          'with soup when you’re sick.',
      interests: const ['Food', 'Advice', 'Family'],
      home: 'Corner diner',
      postCount: 0,
      friendIds: const ['mina', 'momo'],
      firstHello: 'Saved you a plate. Coming by tonight?',
      voice: 'Big & cozy',
      profilePicture: picture('bo', 'Apron on, grill hot.', 58),
      isFriend: true,
    ),
    Character(
      id: 'pip',
      name: 'Pip',
      portraitAsset: 'assets/images/portrait_pip.png',
      tagline:
          'Nursing student who studies all night and remembers every little '
          'thing you tell her.',
      bio:
          'Studies all night, works part time, and remembers every little '
          'thing you tell her.',
      interests: const ['Study', 'Health', 'Feelings'],
      home: 'Campus',
      postCount: 0,
      friendIds: const ['vera'],
      firstHello: 'Sorry, just saw this! Are we okay?',
      voice: 'Soft & careful',
      profilePicture: picture('pip', 'Third coffee. Still studying.', 41),
      isFriend: true,
    ),
    Character(
      id: 'vera',
      name: 'Vera',
      portraitAsset: 'assets/images/portrait_vera.png',
      tagline: 'Startup team lead. Honest, even when it stings.',
      bio:
          'Ambitious startup team lead. Ask her for feedback only if you want '
          'the truth.',
      interests: const ['Work', 'Career', 'Goals'],
      home: 'Downtown',
      postCount: 0,
      friendIds: const ['mina', 'bo'],
      firstHello:
          'Interviewed twenty people this week. Hired two. '
          'Bring your best answer.',
      voice: 'Sharp & direct',
      profilePicture: picture('vera', 'New role, same coffee.', 112),
    ),
    Character(
      id: 'momo',
      name: 'Momo',
      portraitAsset: 'assets/images/portrait_momo.png',
      tagline: 'Plant shop owner who is never in a hurry.',
      bio:
          'Owns a sleepy little plant shop. Never judges, never rushes, and '
          'says “it’s fine” a lot.',
      interests: const ['Plants', 'Chill', 'Small talk'],
      home: 'Plant shop',
      postCount: 0,
      friendIds: const ['bo'],
      firstHello: 'No rush. The ferns and I will be here.',
      voice: 'Slow & mellow',
      profilePicture: picture('momo', 'Found a new leaf. Wearing it.', 73),
    ),
    Character(
      id: 'ziggy',
      name: 'Ziggy',
      portraitAsset: 'assets/images/portrait_ziggy.png',
      tagline: 'Content creator who knows everyone in town.',
      bio:
          'Small-time content creator who knows everyone in town. Brings you '
          'to every party, and every secret.',
      interests: const ['Parties', 'Trends', 'Gossip'],
      home: 'Everywhere',
      postCount: 0,
      friendIds: const ['mina'],
      firstHello: 'Okay, you did NOT hear this from me…',
      voice: 'Loud & lively',
      profilePicture: picture('ziggy', 'New hair, who dis.', 205),
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
  };
}
