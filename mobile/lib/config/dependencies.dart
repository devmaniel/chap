import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_local.dart';
import '../data/repositories/chat/chat_repository.dart';
import '../data/repositories/chat/chat_repository_local.dart';
import '../domain/models/chat/chat.dart';
import '../domain/models/message/message.dart';
import '../ui/chat/view_model/chat_viewmodel.dart';
import '../ui/chats/view_model/chats_viewmodel.dart';

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
      );
    },
  ),
  ...chatViewModelProviders,
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
