import 'dart:convert';

import 'package:app/data/repositories/character/character_repository_local.dart';
import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/chat/chat_repository_local.dart';
import 'package:app/data/repositories/chat/chat_repository_remote.dart';
import 'package:app/data/services/api_service.dart';
import 'package:app/domain/models/chat/chat.dart';
import 'package:app/ui/chat/view_model/chat_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  ChatRepositoryLocal repository({
    List<Exception> sendFailures = const [],
    List<Exception> replyFailures = const [],
  }) => ChatRepositoryLocal(
    latency: const Duration(milliseconds: 100),
    replyDelay: const Duration(seconds: 1),
    chats: [
      Chat(
        id: 'mina',
        friendName: 'Mina',
        portraitAsset: 'assets/images/portrait_mina.png',
        friendVoice: 'Warm & gentle',
        lastMessage: 'Hi',
        lastMessageAt: DateTime(2026, 10, 18),
        unreadCount: 0,
      ),
    ],
    sendFailures: sendFailures,
    replyFailures: replyFailures,
  );

  Future<ChatViewModel> load(
    WidgetTester tester,
    ChatRepositoryLocal repository,
  ) async {
    final model = ChatViewModel(
      chatId: 'mina',
      characterRepository: CharacterRepositoryLocal(),
      chatRepository: repository,
      retryDelay: const Duration(seconds: 2),
    );
    await tester.pump(const Duration(milliseconds: 100));
    addTearDown(model.dispose);
    return model;
  }

  testWidgets(
    'send moves through pending, thinking and reveal without duplicate submissions',
    (tester) async {
      final model = await load(tester, repository());
      model.setDraft('  Hello Mina  ');
      model.submit();
      model.submit();
      expect(model.pending?.text, 'Hello Mina');
      expect(model.pendingStatus, PendingStatus.sending);
      expect(model.canSend, isFalse);
      await tester.pump(const Duration(milliseconds: 100));
      expect(model.messages, hasLength(1));
      expect(model.pending, isNull);
      expect(model.reply.running, isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(model.messages, hasLength(2));
      expect(model.revealingMessageId, model.messages.last.id);
      model.setDraft('Next');
      expect(model.canSend, isFalse);
      model.finishReveal();
      expect(model.canSend, isTrue);
    },
  );

  testWidgets('failed sends keep their content and retry only once', (
    tester,
  ) async {
    final model = await load(
      tester,
      repository(sendFailures: [Exception('send')]),
    );
    model.setDraft('Keep this thought');
    model.submit();
    await tester.pump(const Duration(milliseconds: 100));
    expect(model.pendingStatus, PendingStatus.failed);
    expect(model.pending?.text, 'Keep this thought');
    expect(model.messages, isEmpty);
    model.retry();
    model.retry();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(model.messages.where((message) => message.isFromYou), hasLength(1));
  });

  testWidgets(
    'offline sends retry automatically and clear the banner after recovery',
    (tester) async {
      final model = await load(
        tester,
        repository(sendFailures: [const OfflineException()]),
      );
      model.setDraft('Wait for me');
      model.submit();
      await tester.pump(const Duration(milliseconds: 100));
      expect(model.isOffline, isTrue);
      expect(model.pendingStatus, PendingStatus.waitingForConnection);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 100));
      expect(model.isOffline, isFalse);
      expect(model.pending, isNull);
      expect(model.messages, hasLength(1));
      await tester.pump(const Duration(seconds: 1));
      expect(model.messages, hasLength(2));
    },
  );

  testWidgets('retrying a failed reply never resends the user message', (
    tester,
  ) async {
    final model = await load(
      tester,
      repository(replyFailures: [Exception('reply')]),
    );
    model.setDraft('Hello');
    model.submit();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    expect(model.reply.error, isTrue);
    expect(model.messages, hasLength(1));
    model.reply.execute();
    await tester.pump(const Duration(seconds: 1));
    expect(model.messages, hasLength(2));
    expect(model.messages.where((message) => message.isFromYou), hasLength(1));
  });

  testWidgets(
    'offline while replying retries the answer, preserving the delivered message',
    (tester) async {
      final model = await load(
        tester,
        repository(replyFailures: [const OfflineException()]),
      );
      model.setDraft('Hello');
      model.submit();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
      expect(model.isOffline, isTrue);
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 1));
      expect(model.isOffline, isFalse);
      expect(
        model.messages.where((message) => message.isFromYou),
        hasLength(1),
      );
      expect(
        model.messages.where((message) => !message.isFromYou),
        hasLength(1),
      );
    },
  );

  testWidgets('leaving during an offline retry cancels future attempts', (
    tester,
  ) async {
    final repo = repository(sendFailures: [const OfflineException()]);
    final model = ChatViewModel(
      chatId: 'mina',
      chatRepository: repo,
      characterRepository: CharacterRepositoryLocal(),
    );
    await tester.pump(const Duration(milliseconds: 100));
    model.setDraft('Hello');
    model.submit();
    await tester.pump(const Duration(milliseconds: 100));
    model.dispose();
    await tester.pump(const Duration(seconds: 10));
    expect(model.messages, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('draft is stored in the repository and cleared on send', (
    tester,
  ) async {
    final repo = repository();
    repo.saveDraft('mina', (text: 'Saved', imagePaths: ['a']));
    final model = await load(tester, repo);
    expect(model.draft, 'Saved');
    expect(model.draftImages, ['a']);

    model.removeImage('a');
    model.setDraft('Edited');
    expect(repo.draftFor('mina')?.text, 'Edited');
    expect(repo.draftFor('mina')?.imagePaths, isEmpty);

    model.submit();
    expect(repo.draftFor('mina'), isNull);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('reply to a post sends it with the message and clears it', (
    tester,
  ) async {
    final model = await load(tester, repository());
    model.attachPost('mina-1');
    expect(model.canSend, isTrue);

    model.setDraft('Love this');
    model.submit();
    expect(model.pending?.postId, 'mina-1');
    await tester.pump(const Duration(milliseconds: 100));
    expect(model.messages.last.postId, 'mina-1');

    await tester.pump(const Duration(seconds: 2));
    expect(model.messages.last.text, contains('post'));
    model.attachPost('mina-1');
    model.removePost();
    expect(model.canSend, isFalse);
  });

  test('a chat known from the inbox loads its messages and is marked read '
      'when shown and after each reply', () async {
    final hello = {
      'id': 'm1',
      'text': 'Hi!',
      'sentAt': '2026-10-26T09:00:00Z',
      'isFromYou': false,
      'postId': null,
      'imageRefs': <String>[],
      'callDurationSeconds': null,
    };
    final chat = {
      'id': 'mina',
      'friendName': 'Mina',
      'friendVoice': 'Bright',
      'lastMessage': hello,
      'unreadCount': 1,
    };
    final requests = <String>[];
    final repository = ChatRepositoryRemote(
      apiService: ApiService(
        client: MockClient((request) async {
          final key = '${request.method} ${request.url.path}';
          requests.add(key);
          return switch (key) {
            'GET /api/chats' => http.Response(jsonEncode([chat]), 200),
            'GET /api/chats/mina' => http.Response(jsonEncode(chat), 200),
            'GET /api/chats/mina/messages' => http.Response(
              jsonEncode([hello]),
              200,
            ),
            'POST /api/chats/mina/messages' => http.Response(
              jsonEncode({...hello, 'id': 'm2', 'isFromYou': true}),
              201,
            ),
            'POST /api/chats/mina/reply' => http.Response(
              jsonEncode({...hello, 'id': 'm3', 'text': 'Hey'}),
              200,
            ),
            _ => http.Response('', 204),
          };
        }),
        baseUrl: Uri.parse('http://server.test'),
      ),
      portraitAssets: const {'mina': 'assets/images/portrait_mina.png'},
    );
    await repository.getChats();

    final model = ChatViewModel(
      chatId: 'mina',
      chatRepository: repository,
      characterRepository: CharacterRepositoryLocal(),
    );
    addTearDown(model.dispose);
    model.setVisible(true);
    await pumpEventQueue();

    expect(model.messages.map((m) => m.text), ['Hi!']);
    expect(repository.cachedChat('mina')!.unreadCount, 0);

    requests.clear();
    model.setDraft('Hello');
    model.submit();
    await pumpEventQueue();

    expect(model.messages, hasLength(3));
    expect(requests, [
      'POST /api/chats/mina/messages',
      'POST /api/chats/mina/reply',
      'POST /api/chats/mina/read',
    ]);
    expect(repository.cachedChat('mina')!.unreadCount, 0);
  });
}
