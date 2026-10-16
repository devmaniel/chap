import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../data/repositories/auth/auth_repository_local.dart';
import '../data/repositories/chat/chat_repository.dart';
import '../data/repositories/chat/chat_repository_local.dart';
import '../domain/models/chat/chat.dart';

/// Swap the local repositories for remote implementations once the server exists.
List<SingleChildWidget> get providers => [
  ChangeNotifierProvider<AuthRepository>(
    create: (_) => AuthRepositoryLocal(
      // Test account. Emails are stored lowercase.
      passwordsByEmail: const {'melco@example.com': 'Password123'},
    ),
  ),
  Provider<ChatRepository>(
    create: (_) => ChatRepositoryLocal(chats: _sampleChats(DateTime.now())),
  ),
];

List<Chat> _sampleChats(DateTime now) => [
  Chat(
    id: 'mina',
    friendName: 'Mina',
    portraitAsset: 'assets/images/portrait_mina.png',
    lastMessage: 'I finally found that little bookshop.',
    lastMessageAt: now.subtract(const Duration(minutes: 12)),
    unreadCount: 2,
  ),
  Chat(
    id: 'kai',
    friendName: 'Kai',
    portraitAsset: 'assets/images/portrait_kai.png',
    lastMessage: 'One song for a rainy walk. Your pick?',
    lastMessageAt: now.subtract(const Duration(hours: 1)),
    unreadCount: 1,
  ),
  Chat(
    id: 'sol',
    friendName: 'Sol',
    portraitAsset: 'assets/images/portrait_sol.png',
    lastMessage: 'Tell me how your sketch turned out.',
    lastMessageAt: now.subtract(const Duration(days: 1)),
    unreadCount: 0,
  ),
];
