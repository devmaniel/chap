import 'dart:convert';

import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/character/character_repository.dart';
import 'package:app/data/repositories/character/character_repository_remote.dart';
import 'package:app/data/services/api_service.dart';
import 'package:app/domain/models/post/post.dart';
import 'package:app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final postedAt = DateTime(2026, 10, 1);

  Post picture(String id) => Post(
    id: '$id-picture',
    characterId: id,
    text: 'Hi',
    postedAt: postedAt,
    likeCount: 3,
  );

  BundledCharacter bundled(String id) => (
    portraitAsset: 'assets/images/portrait_$id.png',
    postCount: 2,
    friendIds: const ['bo'],
    profilePicture: picture(id),
  );

  Map<String, Object> fromServer(String id, {bool isFriend = false}) => {
    'id': id,
    'name': id.toUpperCase(),
    'tagline': 'Tagline',
    'bio': 'Bio',
    'interests': ['Food'],
    'home': 'Home',
    'voice': 'Warm',
    'firstHello': 'Hello',
    'isFriend': isFriend,
  };

  late List<http.Request> sent;

  /// Bundles Mina then Bo; the server answers every request with [respond].
  CharacterRepositoryRemote repository(
    Future<http.Response> Function(http.Request request) respond,
  ) {
    sent = [];
    return CharacterRepositoryRemote(
      apiService: ApiService(
        client: MockClient((request) {
          sent.add(request);
          return respond(request);
        }),
        baseUrl: Uri.parse('http://server.test'),
      ),
      bundled: {'mina': bundled('mina'), 'bo': bundled('bo')},
      posts: {
        'mina': [
          Post(
            id: 'mina-1',
            characterId: 'mina',
            text: 'Beach',
            postedAt: postedAt,
            likeCount: 5,
          ),
        ],
      },
    );
  }

  Future<http.Response> characters() async => http.Response(
    jsonEncode([
      fromServer('bo', isFriend: true),
      fromServer('mina'),
      fromServer('newcomer'),
    ]),
    200,
  );

  test('has nothing cached before loading', () {
    final repo = repository((_) => characters());

    expect(repo.cachedCharacters, isNull);
    expect(repo.cachedPosts('mina'), isNull);
  });

  test('merges server profiles with bundled parts, in bundled order', () async {
    final repo = repository((_) => characters());
    var notified = 0;
    repo.addListener(() => notified++);

    final result = await repo.getCharacters();

    expect(sent.single.url.path, '/api/characters');
    final loaded = (result as Ok).value;
    expect(loaded.map((c) => c.id), ['mina', 'bo']);
    final bo = repo.cachedCharacter('bo')!;
    expect(bo.name, 'BO');
    expect(bo.voice, 'Warm');
    expect(bo.isFriend, isTrue);
    expect(bo.portraitAsset, 'assets/images/portrait_bo.png');
    expect(bo.friendIds, ['bo']);
    expect(repo.cachedPosts('mina')!.single.id, 'mina-1');
    expect(notified, 1);
  });

  test('a load while offline is an OfflineException', () async {
    final repo = repository(
      (_) => throw http.ClientException('Connection refused'),
    );

    final result = await repo.getCharacters();

    expect((result as Error).error, isA<OfflineException>());
    expect(repo.cachedCharacters, isNull);
  });

  test('adding and removing a friend calls the server', () async {
    final repo = repository(
      (request) => request.url.path == '/api/characters'
          ? characters()
          : Future.value(http.Response('', 204)),
    );
    await repo.getCharacters();

    await repo.setFriend('mina', isFriend: true);
    expect(sent.last.method, 'PUT');
    expect(sent.last.url.path, '/api/friends/mina');
    expect(repo.cachedCharacter('mina')!.isFriend, isTrue);

    await repo.setFriend('mina', isFriend: false);
    expect(sent.last.method, 'DELETE');
    expect(repo.cachedCharacter('mina')!.isFriend, isFalse);
  });

  test('an unknown character is a CharacterNotFoundException', () async {
    final repo = repository(
      (_) async => http.Response('{"code":"character_not_found"}', 404),
    );

    final result = await repo.setFriend('nobody', isFriend: true);

    expect((result as Error).error, isA<CharacterNotFoundException>());
  });

  test('likes stay on the device and survive a reload', () async {
    final repo = repository((_) => characters());
    await repo.getCharacters();

    await repo.setLiked('mina-picture', isLiked: true);
    await repo.setLiked('mina-1', isLiked: true);
    await repo.getCharacters();

    expect(sent.where((r) => r.url.path != '/api/characters'), isEmpty);
    expect(repo.cachedCharacter('mina')!.profilePicture.isLiked, isTrue);
    expect(repo.cachedPost('mina-1')!.isLiked, isTrue);
  });
}
