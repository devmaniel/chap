import 'dart:io';

import 'package:app/data/repositories/character/character_repository_local.dart';
import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/chat/chat_repository_local.dart';
import 'package:app/data/services/photo_library_service.dart';
import 'package:app/domain/models/chat/chat.dart';
import 'package:app/domain/models/message/message.dart';
import 'package:app/ui/chat/view_model/chat_viewmodel.dart';
import 'package:app/ui/chat/widgets/chat_screen.dart';
import 'package:app/ui/chat/widgets/chat_animations.dart';
import 'package:app/ui/core/themes/theme.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PhotoLibrary extends PhotoLibraryService {
  static final paths = [
    File('assets/images/portrait_mina.png').absolute.path,
    File('assets/images/portrait_bo.png').absolute.path,
  ];

  @override
  Future<Result<List<PhotoData>>> getPhotos(int page) async => Result.ok([
    if (page == 0)
      for (var i = 0; i < paths.length; i++)
        (id: '$i', thumbnail: File(paths[i]).readAsBytesSync()),
  ]);

  @override
  Future<Result<List<String>>> getImagePaths(List<String> ids) async =>
      Result.ok([for (final id in ids) paths[int.parse(id)]]);
}

void main() {
  Future<ChatViewModel> pumpChat(
    WidgetTester tester, {
    List<Exception> sendFailures = const [],
    List<Exception> replyFailures = const [],
    double textScale = 1,
    bool reducedMotion = false,
  }) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final model = ChatViewModel(
      chatId: 'mina',
      retryDelay: const Duration(seconds: 2),
      characterRepository: CharacterRepositoryLocal(),
      chatRepository: ChatRepositoryLocal(
        latency: const Duration(milliseconds: 100),
        replyDelay: const Duration(seconds: 1),
        sendFailures: sendFailures,
        replyFailures: replyFailures,
        photoLibraryService: _PhotoLibrary(),
        chats: [
          Chat(
            id: 'mina',
            friendName: 'Mina',
            portraitAsset: 'assets/images/portrait_mina.png',
            friendVoice: 'Warm & gentle',
            lastMessage: 'Hello',
            lastMessageAt: DateTime(2026, 10, 18),
            unreadCount: 0,
          ),
        ],
        messages: {
          'mina': [
            Message(
              id: 'seed',
              text: 'Find anything worth a second look?',
              sentAt: DateTime(2026, 10, 18, 9, 41),
              isFromYou: false,
            ),
          ],
        },
      ),
    );
    addTearDown(model.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reducedMotion,
          ),
          child: child!,
        ),
        home: ChatScreen(viewModel: model),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    return model;
  }

  Future<void> send(WidgetTester tester, String text) async {
    await tester.enterText(find.byType(TextField), text);
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump();
  }

  testWidgets('shows seeded history, sending, thinking and an animated reply', (
    tester,
  ) async {
    final model = await pumpChat(tester);
    expect(find.text('Find anything worth a second look?'), findsOneWidget);
    await send(tester, 'I sketched a bookshop.');
    expect(find.text('Sending…'), findsOneWidget);
    expect(
      find.byType(TextField).evaluate().single.widget,
      isA<TextField>().having(
        (field) => field.controller?.text,
        'draft',
        isEmpty,
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel('Mina is thinking'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));
    final answer = model.messages.last.text;
    expect(find.byType(BubblePop), findsOneWidget);
    expect(model.revealingMessageId, isNotNull);
    await tester.pumpAndSettle();
    expect(find.text(answer), findsOneWidget);
    expect(model.revealingMessageId, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'failure keeps the bubble and Retry delivers it without duplication',
    (tester) async {
      final model = await pumpChat(tester, sendFailures: [Exception('send')]);
      await send(tester, 'Keep my message');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Something went wrong.'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        model.messages.where((message) => message.text == 'Keep my message'),
        hasLength(1),
      );
    },
  );

  testWidgets('offline banner recovers automatically at 2x text size', (
    tester,
  ) async {
    await pumpChat(
      tester,
      sendFailures: [const OfflineException()],
      textScale: 2,
    );
    await send(tester, 'Hello');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('No internet. Trying again…'), findsOneWidget);
    expect(find.text('Waiting for connection…'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('No internet. Trying again…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'real-library boundary supports ordered picks, removal and photo-only sending at 2x text',
    (tester) async {
      final model = await pumpChat(tester, textScale: 2);
      await tester.tap(find.byTooltip('Share a photo'));
      await tester.pumpAndSettle();
      expect(find.text('Recents'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Photo 2'));
      await tester.pump();
      await tester.tap(find.bySemanticsLabel('Photo 1'));
      await tester.pump();
      expect(model.selectedPhotos, ['1', '0']);
      final beforeDrag = tester.getTopLeft(find.text('Recents')).dy;
      await tester.drag(
        find.byKey(const ValueKey('photo-sheet-handle')),
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.text('Recents')).dy, lessThan(beforeDrag));
      expect(model.selectedPhotos, ['1', '0']);
      await tester.tap(find.text('Add 2'));
      await tester.pumpAndSettle();
      expect(model.draftImages, [
        _PhotoLibrary.paths[1],
        _PhotoLibrary.paths[0],
      ]);
      await tester.tap(find.byTooltip('Remove photo 1'));
      await tester.pump();
      expect(model.draftImages, [_PhotoLibrary.paths[0]]);
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        model.messages.where((message) => message.isFromYou).single.imagePaths,
        [_PhotoLibrary.paths[0]],
      );
      expect(model.messages.last.text, contains('colors'));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('retrying a failed answer keeps exactly one user message', (
    tester,
  ) async {
    final model = await pumpChat(tester, replyFailures: [Exception('reply')]);
    await send(tester, 'One message');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Couldn’t get a reply.'), findsOneWidget);
    await tester.tap(find.text('Retry reply'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(model.messages.where((message) => message.isFromYou), hasLength(1));
    expect(find.text('Couldn’t get a reply.'), findsNothing);
  });

  testWidgets(
    'canceling the gallery preserves the typed draft without attaching picks',
    (tester) async {
      final model = await pumpChat(tester);
      await tester.enterText(find.byType(TextField), 'Keep my draft');
      await tester.pump();
      await tester.tap(find.byTooltip('Share a photo'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Photo 1'));
      await tester.tap(find.byTooltip('Close photos'));
      await tester.pumpAndSettle();
      expect(model.draftImages, isEmpty);
      expect(find.text('Keep my draft'), findsOneWidget);
      expect(model.canSend, isTrue);
    },
  );

  testWidgets('multiline input and the keyboard fit at 360dp with 2x text', (
    tester,
  ) async {
    await pumpChat(tester, textScale: 2);
    await tester.enterText(
      find.byType(TextField),
      'A long thought\nwith a second line\nand a third line\nand one more',
    );
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    await tester.pump();
    expect(
      tester.getBottomRight(find.byTooltip('Send message')).dy,
      lessThanOrEqualTo(480),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduced motion shows the complete reply immediately', (
    tester,
  ) async {
    final model = await pumpChat(tester, reducedMotion: true);
    await send(tester, 'Hello');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text(model.messages.last.text), findsOneWidget);
    expect(model.revealingMessageId, isNull);
    expect(tester.takeException(), isNull);
  });
}
