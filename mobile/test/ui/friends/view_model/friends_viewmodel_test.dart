import 'package:app/data/repositories/character/character_repository_local.dart';
import 'package:app/domain/models/character/character.dart';
import 'package:app/domain/models/post/post.dart';
import 'package:app/ui/friends/view_model/friends_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

Character character(String id, {bool isFriend = false}) => Character(
  id: id,
  name: id,
  portraitAsset: 'assets/images/portrait_$id.png',
  tagline: 'Tagline',
  bio: 'Bio',
  interests: const ['Art'],
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
  isFriend: isFriend,
);

void main() {
  test('lists only friends and drops one once removed', () async {
    final repository = CharacterRepositoryLocal(
      latency: Duration.zero,
      characters: [
        character('mina', isFriend: true),
        character('kai', isFriend: true),
        character('lumi'),
      ],
    );
    final viewModel = FriendsViewModel(characterRepository: repository);
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.friends.map((c) => c.id), ['mina', 'kai']);

    await repository.setFriend('mina', isFriend: false);

    expect(viewModel.friends.map((c) => c.id), ['kai']);
  });

  test('load failure surfaces as an error', () async {
    final viewModel = FriendsViewModel(
      characterRepository: CharacterRepositoryLocal(
        latency: Duration.zero,
        loadFailures: [Exception('down')],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(viewModel.load.error, isTrue);
  });

  test('count label is singular for one friend', () {
    expect(friendCountLabel(1), '1 friend');
    expect(friendCountLabel(3), '3 friends');
  });
}
