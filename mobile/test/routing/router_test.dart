import 'dart:io';
import 'dart:async';

import 'package:app/config/dependencies.dart';
import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/auth/auth_repository_local.dart';
import 'package:app/data/repositories/chat/chat_repository.dart';
import 'package:app/data/repositories/chat/chat_repository_local.dart';
import 'package:app/domain/models/chat/chat.dart';
import 'package:app/domain/models/message/message.dart';
import 'package:app/routing/router.dart';
import 'package:app/ui/chat/view_model/chat_viewmodel.dart';
import 'package:app/ui/chat/widgets/chat_animations.dart';
import 'package:app/ui/chat/widgets/chat_screen.dart';
import 'package:app/ui/chats/widgets/chats_screen.dart';
import 'package:app/ui/chats/widgets/chat_tile.dart';
import 'package:app/ui/core/themes/theme.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class _CountingRepository extends ChatRepositoryLocal {
  _CountingRepository({
    super.replyDelay = const Duration(milliseconds: 100),
    super.sendFailures = const [],
    this.sendGate,
  }) : super(
         latency: const Duration(milliseconds: 100),
         chats: [
           Chat(
             id: 'mina',
             friendName: 'Mina',
             portraitAsset: 'assets/images/portrait_mina.png',
             friendVoice: 'Warm & gentle',
             lastMessage: 'Hello there',
             lastMessageAt: DateTime.now(),
             unreadCount: 0,
           ),
         ],
       );

  int reads = 0;
  final Completer<void>? sendGate;

  @override
  Future<Result<Message>> sendMessage({
    required String chatId,
    required String text,
    List<String> imagePaths = const [],
  }) async {
    await sendGate?.future;
    return super.sendMessage(
      chatId: chatId,
      text: text,
      imagePaths: imagePaths,
    );
  }

  @override
  Future<Result<List<Chat>>> getChats() {
    reads++;
    return super.getChats();
  }

  @override
  Future<Result<Chat>> getChat(String chatId) {
    reads++;
    return super.getChat(chatId);
  }

  @override
  Future<Result<List<Message>>> getMessages(String chatId) {
    reads++;
    return super.getMessages(chatId);
  }

  @override
  Future<Result<List<String>>> getImagePaths(List<String> ids) async =>
      Result.ok([File('assets/images/portrait_mina.png').absolute.path]);
}

Future<GoRouter> _pumpApp(
  WidgetTester tester,
  _CountingRepository chats,
) async {
  final auth = AuthRepositoryLocal(
    latency: Duration.zero,
    passwordsByEmail: const {'melco@example.com': 'Password123'},
  );
  await tester.runAsync(
    () => auth.signIn(email: 'melco@example.com', password: 'Password123'),
  );
  final appRouter = router(auth);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    appRouter.dispose();
    auth.dispose();
    chats.dispose();
  });
  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthRepository>.value(value: auth),
        ChangeNotifierProvider<ChatRepository>.value(value: chats),
        ...chatViewModelProviders,
      ],
      child: MaterialApp.router(theme: AppTheme.light, routerConfig: appRouter),
    ),
  );
  await tester.pumpAndSettle();
  return appRouter;
}

Future<ChatViewModel> _openChat(WidgetTester tester) async {
  await tester.tap(find.byType(ChatTile).first);
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  await tester.pump();
  return tester.widget<ChatScreen>(find.byType(ChatScreen)).viewModel;
}

Future<void> _back(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Back to chats'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'open chat, send a message, go back and see the updated inbox without reloading',
    (tester) async {
      final repository = _CountingRepository();
      await _pumpApp(tester, repository);
      await _openChat(tester);
      await tester.enterText(find.byType(TextField), 'Hello Mina');
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      await _back(tester);
      expect(find.byType(ChatsScreen), findsOneWidget);
      expect(
        find.text('I love that. What made you notice it?'),
        findsOneWidget,
      );
      expect(repository.reads, 0);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'search, draft and picked photos survive back navigation and router refresh',
    (tester) async {
      final repository = _CountingRepository();
      final appRouter = await _pumpApp(tester, repository);
      await tester.tap(find.byTooltip('Search chats'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'Mina');
      await tester.pump();
      final model = await _openChat(tester);
      await tester.enterText(find.byType(TextField), 'Keep this draft');
      await tester.pump();
      model.togglePhoto('one');
      final attach = model.attachImages.execute();
      await tester.pump();
      await attach;
      await _back(tester);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        'Mina',
      );
      final reopened = await _openChat(tester);
      expect(identical(reopened, model), isTrue);
      expect(find.text('Keep this draft'), findsOneWidget);
      expect(find.byTooltip('Remove photo 1'), findsOneWidget);
      appRouter.refresh();
      await tester.pumpAndSettle();
      expect(
        identical(
          tester.widget<ChatScreen>(find.byType(ChatScreen)).viewModel,
          model,
        ),
        isTrue,
      );
      expect(find.text('Keep this draft'), findsOneWidget);
      expect(repository.reads, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'sending and thinking continue across navigation and finished replies do not replay',
    (tester) async {
      final sendGate = Completer<void>();
      final repository = _CountingRepository(
        sendGate: sendGate,
        replyDelay: const Duration(seconds: 2),
      );
      await _pumpApp(tester, repository);
      final model = await _openChat(tester);
      await tester.enterText(find.byType(TextField), 'Keep sending');
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump();
      await _back(tester);
      expect(model.send.running, isTrue);
      expect(identical(await _openChat(tester), model), isTrue);
      sendGate.complete();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(model.reply.running, isTrue);
      await _back(tester);
      await tester.pump(const Duration(seconds: 2));
      expect(model.reply.completed, isTrue);
      expect(identical(await _openChat(tester), model), isTrue);
      expect(
        model.messages.where((message) => message.isFromYou),
        hasLength(1),
      );
      expect(
        model.messages.where((message) => !message.isFromYou),
        hasLength(1),
      );
      expect(find.byType(ReplyText), findsNothing);
      expect(find.text(model.messages.last.text), findsOneWidget);
      expect(repository.reads, 0);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'a failed pending message remains retryable after leaving and reopening',
    (tester) async {
      final repository = _CountingRepository(sendFailures: [Exception('send')]);
      await _pumpApp(tester, repository);
      final model = await _openChat(tester);
      await tester.enterText(find.byType(TextField), 'Do not lose this');
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      await _back(tester);
      expect(identical(await _openChat(tester), model), isTrue);
      expect(find.text('Do not lose this'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(
        model.messages.where((message) => message.isFromYou),
        hasLength(1),
      );
      expect(repository.reads, 0);
    },
  );
}
