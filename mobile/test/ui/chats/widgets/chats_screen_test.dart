import 'package:app/data/repositories/chat/chat_repository_local.dart';
import 'package:app/domain/models/chat/chat.dart';
import 'package:app/ui/chats/view_model/chats_viewmodel.dart';
import 'package:app/ui/chats/widgets/chats_screen.dart';
import 'package:app/ui/core/themes/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpScreen(
    WidgetTester tester, {
    void Function(ChatRepositoryLocal repository)? arrange,
  }) async {
    final now = DateTime.now();
    final repository = ChatRepositoryLocal(
      latency: Duration.zero,
      chats: [
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
          id: 'pip',
          friendName: 'Pip',
          portraitAsset: 'assets/images/portrait_pip.png',
          friendVoice: 'Warm & gentle',
          lastMessage: 'Tell me how your sketch turned out.',
          lastMessageAt: now.subtract(const Duration(days: 1)),
          unreadCount: 0,
        ),
      ],
    );
    arrange?.call(repository);
    final viewModel = ChatsViewModel(chatRepository: repository);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ChatsScreen(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lists chats with time, unread count and the tab bar', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('12m'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Pip'), findsOneWidget);
    expect(find.text('Yesterday'), findsOneWidget);
    expect(find.text('Meet someone new'), findsOneWidget);
    for (final tab in ['CHATS', 'DISCOVER', 'FRIENDS']) {
      expect(find.text(tab), findsOneWidget);
    }
  });

  testWidgets('search narrows the list, shows no matches, cancel restores', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byTooltip('Search chats'));
    await tester.pump();
    expect(find.text('ALL CHATS'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'book');
    await tester.pump();
    expect(find.text('1 CHAT'), findsOneWidget);
    expect(find.text('Pip'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zebra');
    await tester.pump();
    expect(find.text('No matches'), findsOneWidget);
    expect(find.text('Nothing for “zebra”.'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Pip'), findsOneWidget);
  });

  testWidgets('survives text scale 2.0 at 360 wide', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
  });

  testWidgets('a draft replaces the preview and unread badge', (tester) async {
    await pumpScreen(
      tester,
      arrange: (repository) => repository.saveDraft('mina', (
        text: 'Half a thought',
        imagePaths: [],
      )),
    );

    expect(find.textContaining('Draft: Half a thought'), findsOneWidget);
    expect(find.textContaining('I finally found'), findsNothing);
    expect(find.text('2'), findsNothing);
  });
}
