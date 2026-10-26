import 'package:app/domain/models/message/message.dart';
import 'package:app/ui/chat/widgets/message_bubble.dart';
import 'package:app/ui/core/themes/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a photo deleted from the phone shows a placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MessageBubble(
            message: Message(
              id: 'm1',
              text: 'Look',
              sentAt: DateTime(2026, 10, 26),
              isFromYou: true,
              imagePaths: const ['/no/such/photo.jpg'],
            ),
            portraitAsset: 'assets/images/portrait_mina.png',
            friendName: 'Mina',
          ),
        ),
      ),
    );
    // Reading the file is real I/O, outside the test's fake clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Photo 1 unavailable'), findsOneWidget);
    expect(find.text('Look'), findsOneWidget);
  });
}
