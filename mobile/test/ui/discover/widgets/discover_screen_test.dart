import 'package:app/data/repositories/character/character_repository_local.dart';
import 'package:app/domain/models/character/character.dart';
import 'package:app/domain/models/post/post.dart';
import 'package:app/ui/core/themes/theme.dart';
import 'package:app/ui/discover/view_model/discover_viewmodel.dart';
import 'package:app/ui/discover/widgets/discover_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Character character(String id, String name, List<String> interests) =>
    Character(
      id: id,
      name: name,
      portraitAsset: 'assets/images/portrait_$id.png',
      tagline: 'Tagline',
      bio: 'Bio',
      interests: interests,
      home: 'Home',
      postCount: 0,
      friendIds: const [],
      firstHello: 'Hi',
      voice: 'Warm & gentle',
      profilePicture: Post(
        id: '$id-picture',
        characterId: id,
        text: 'Me',
        postedAt: DateTime(2026),
        likeCount: 0,
      ),
    );

void main() {
  testWidgets('filters narrow the cards to one interest at a time', (
    tester,
  ) async {
    final viewModel = DiscoverViewModel(
      characterRepository: CharacterRepositoryLocal(
        latency: Duration.zero,
        characters: [
          character('mina', 'Mina', ['Art', 'Coffee']),
          character('kai', 'Kai', ['Music', 'Ideas']),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DiscoverScreen(viewModel: viewModel),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Discover'), findsWidgets);
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Kai'), findsOneWidget);
    expect(find.text('Art · Coffee'), findsOneWidget);

    await tester.tap(find.text('Art'));
    await tester.pump();

    expect(viewModel.filter, 'Art');
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Kai'), findsNothing);

    await tester.tap(find.text('All'));
    await tester.pump();

    expect(find.text('Kai'), findsOneWidget);
  });

  testWidgets('a failed load shows Retry, which brings the cards', (
    tester,
  ) async {
    final viewModel = DiscoverViewModel(
      characterRepository: CharacterRepositoryLocal(
        latency: Duration.zero,
        characters: [
          character('mina', 'Mina', ['Art']),
        ],
        loadFailures: [Exception('offline')],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: DiscoverScreen(viewModel: viewModel),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Mina'), findsNothing);

    await tester.tap(find.text('RETRY'));
    await tester.pump(const Duration(milliseconds: 1));

    expect(find.text('Something went wrong'), findsNothing);
    expect(find.text('Mina'), findsOneWidget);
  });
}
