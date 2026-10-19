import 'package:app/data/repositories/character/character_repository_local.dart';
import 'package:app/data/repositories/chat/chat_repository_local.dart';
import 'package:app/domain/models/character/character.dart';
import 'package:app/domain/models/post/post.dart';
import 'package:app/ui/profile/view_model/profile_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

Character character(String id, {List<String> friendIds = const []}) =>
    Character(
      id: id,
      name: id.toUpperCase(),
      portraitAsset: 'assets/images/portrait_$id.png',
      tagline: 'Tagline',
      bio: 'Bio',
      interests: const ['Art'],
      home: 'Old town',
      postCount: 1,
      friendIds: friendIds,
      firstHello: 'Hi',
      voice: 'Warm & gentle',
      profilePicture: Post(
        id: '$id-picture',
        characterId: id,
        text: 'Me',
        postedAt: DateTime(2026),
        likeCount: 3,
      ),
    );

void main() {
  late CharacterRepositoryLocal repository;
  late ChatRepositoryLocal chatRepository;
  late ProfileViewModel viewModel;

  setUp(() async {
    repository = CharacterRepositoryLocal(
      latency: Duration.zero,
      characters: [
        character('mina', friendIds: ['kai', 'missing']),
        character('kai'),
      ],
      posts: {
        'mina': [
          Post(
            id: 'p1',
            characterId: 'mina',
            text: 'Coast',
            postedAt: DateTime(2026),
            likeCount: 10,
            photos: const [
              PostPhoto(
                scene: PhotoScene.sea,
                shape: PhotoShape.wide,
                description: 'sea',
              ),
              PostPhoto(
                scene: PhotoScene.mint,
                shape: PhotoShape.portrait,
                description: 'sky',
              ),
            ],
          ),
        ],
      },
    );
    await repository.getCharacters();
    viewModel = ProfileViewModel(
      characterId: 'mina',
      characterRepository: repository,
      chatRepository: chatRepository = ChatRepositoryLocal(
        latency: Duration.zero,
      ),
    );
  });

  test('add friend then remove friend flips the character', () async {
    expect(viewModel.character!.isFriend, isFalse);

    await viewModel.addFriend.execute();
    expect(viewModel.character!.isFriend, isTrue);

    await viewModel.removeFriend.execute();
    expect(viewModel.character!.isFriend, isFalse);
  });

  test('adding a friend starts a chat with their first hello', () async {
    await viewModel.addFriend.execute();

    expect(chatRepository.cachedChat('mina')!.lastMessage, 'Hi');
    expect(chatRepository.cachedMessages('mina').single.isFromYou, isFalse);
  });

  test('like adds one and liking again takes it back', () async {
    await viewModel.toggleLike.execute(viewModel.posts.single);
    expect(viewModel.posts.single.isLiked, isTrue);
    expect(viewModel.posts.single.likeCount, 11);

    await viewModel.toggleLike.execute(viewModel.posts.single);
    expect(viewModel.posts.single.likeCount, 10);
  });

  test('profile picture likes are found by post id', () async {
    await repository.setLiked('mina-picture', isLiked: true);

    expect(repository.cachedPost('mina-picture')!.likeCount, 4);
  });

  test('photos lists every picture with its post and index', () {
    expect([for (final p in viewModel.photos) p.index], [0, 1]);
  });

  test('friends skips ids that are not characters', () {
    expect([for (final f in viewModel.friends) f.id], ['kai']);
  });

  test('friendsLabel joins names the way the profile reads', () {
    expect(friendsLabel(['Kai']), 'Friends with Kai');
    expect(friendsLabel(['Kai', 'Sol']), 'Friends with Kai and Sol');
    expect(friendsLabel(['A', 'B', 'C']), 'Friends with A, B and C');
  });

  test('postTimeLabel matches the mockup wording', () {
    final now = DateTime(2026, 10, 19, 12);
    String label(Duration ago) => postTimeLabel(now.subtract(ago), now);

    expect(label(const Duration(minutes: 5)), '5m');
    expect(label(const Duration(hours: 2)), '2h');
    expect(label(const Duration(days: 1, hours: 3)), 'Yesterday');
    expect(label(const Duration(days: 3)), '3 days ago');
    expect(label(const Duration(days: 14)), '2 weeks ago');
  });

  test('postMetaLabel names a profile picture', () {
    final picture = viewModel.character!.profilePicture;

    expect(
      postMetaLabel(picture, DateTime(2026, 1, 15)),
      'Profile picture · 2 weeks ago',
    );
  });
}
