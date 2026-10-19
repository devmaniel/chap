import 'package:app/data/repositories/character/character_repository_local.dart';
import 'package:app/ui/core/themes/theme.dart';
import 'package:app/ui/friends/view_model/friends_viewmodel.dart';
import 'package:app/ui/friends/widgets/friends_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../view_model/friends_viewmodel_test.dart';

void main() {
  testWidgets('shows a card per friend with the count', (tester) async {
    final viewModel = FriendsViewModel(
      characterRepository: CharacterRepositoryLocal(
        latency: Duration.zero,
        characters: [
          character('mina', isFriend: true),
          character('kai', isFriend: true),
          character('lumi'),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: FriendsScreen(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('2 friends'), findsOneWidget);
    expect(find.text('mina'), findsOneWidget);
    expect(find.text('kai'), findsOneWidget);
    expect(find.text('lumi'), findsNothing);
  });
}
