import 'dart:convert';
import 'dart:io';

import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/chat/chat_repository.dart';
import 'package:app/data/repositories/chat/chat_repository_remote.dart';
import 'package:app/data/services/api_service.dart';
import 'package:app/data/services/image_compress_service.dart';
import 'package:app/data/services/voice_call_service.dart';
import 'package:app/domain/models/chat/chat.dart';
import 'package:app/utils/result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// "Compresses" a photo into its path's bytes; a deleted photo fails.
class _FakeCompress extends ImageCompressService {
  @override
  Future<Result<Uint8List>> jpeg(String path) async => path.contains('deleted')
      ? Result.error(FileSystemException('Photo not found', path))
      : Result.ok(utf8.encode('jpeg of $path'));
}

/// Stands in for ElevenLabs: records the call it was asked to start.
class _FakeVoiceCalls extends ChangeNotifier implements VoiceCallService {
  _FakeVoiceCalls({this.microphone = true});

  final bool microphone;
  ({
    String conversationToken,
    String prompt,
    String firstMessage,
    String voiceId,
  })?
  started;
  bool _isConnected = false;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> requestMicrophone() async => microphone;

  @override
  Future<Result<void>> start({
    required String conversationToken,
    required String prompt,
    required String firstMessage,
    required String voiceId,
  }) async {
    started = (
      conversationToken: conversationToken,
      prompt: prompt,
      firstMessage: firstMessage,
      voiceId: voiceId,
    );
    _isConnected = true;
    notifyListeners();
    return const Result.ok(null);
  }

  @override
  Future<void> end() async {
    _isConnected = false;
    notifyListeners();
  }

  void drop() {
    _isConnected = false;
    notifyListeners();
  }
}

void main() {
  Map<String, Object?> message(
    String id,
    String text, {
    String sentAt = '2026-10-26T09:00:00Z',
    bool isFromYou = false,
    String? postId,
    List<String> imageRefs = const [],
    int? callDurationSeconds,
  }) => {
    'id': id,
    'text': text,
    'sentAt': sentAt,
    'isFromYou': isFromYou,
    'postId': postId,
    'imageRefs': imageRefs,
    'callDurationSeconds': callDurationSeconds,
  };

  Map<String, Object?> chat(
    String id,
    Map<String, Object?> lastMessage, {
    int unreadCount = 1,
  }) => {
    'id': id,
    'friendName': id.toUpperCase(),
    'friendVoice': 'Warm',
    'lastMessage': lastMessage,
    'unreadCount': unreadCount,
  };

  final minaChat = chat(
    'mina',
    message('m1', 'Hi!', sentAt: '2026-10-26T08:00:00Z'),
  );
  final boChat = chat(
    'bo',
    message('b1', 'Plate saved.', sentAt: '2026-10-26T09:30:00Z'),
  );

  late List<http.Request> sent;
  late _FakeVoiceCalls voiceCalls;

  /// Answers each `METHOD /path` from [routes] as JSON; anything else is 404.
  ChatRepositoryRemote repository(
    Map<String, Object?> routes, {
    bool microphone = true,
  }) {
    sent = [];
    voiceCalls = _FakeVoiceCalls(microphone: microphone);
    return ChatRepositoryRemote(
      apiService: ApiService(
        client: MockClient((request) async {
          sent.add(request);
          final key = '${request.method} ${request.url.path}';
          if (!routes.containsKey(key)) {
            return http.Response('{"code":"chat_not_found"}', 404);
          }
          final body = routes[key];
          return body == null
              ? http.Response('', 204)
              : http.Response(jsonEncode(body), 200);
        }),
        baseUrl: Uri.parse('http://server.test'),
      ),
      portraitAssets: const {
        'mina': 'assets/images/portrait_mina.png',
        'bo': 'assets/images/portrait_bo.png',
      },
      imageCompressService: _FakeCompress(),
      voiceCallService: voiceCalls,
    );
  }

  test(
    'loads the inbox newest first, with portraits and local times',
    () async {
      final repo = repository({
        'GET /api/chats': [
          minaChat,
          boChat,
          chat('newcomer', message('n1', 'Hey')),
        ],
      });
      expect(repo.cachedChats, isNull);

      final result = await repo.getChats();

      final chats = (result as Ok<List<Chat>>).value;
      expect(chats.map((c) => c.id), ['bo', 'mina']);
      expect(chats.first.portraitAsset, 'assets/images/portrait_bo.png');
      expect(chats.first.lastMessage, 'Plate saved.');
      expect(
        chats.first.lastMessageAt.isAtSameMomentAs(
          DateTime.utc(2026, 10, 26, 9, 30),
        ),
        isTrue,
      );
      expect(chats.first.lastMessageAt.isUtc, isFalse);
      expect(repo.cachedChats!.map((c) => c.id), ['bo', 'mina']);
    },
  );

  test('starting a chat asks the server and caches it', () async {
    final repo = repository({'PUT /api/chats/mina': minaChat});

    final result = await repo.startChat(
      Chat(
        id: 'mina',
        friendName: 'Mina',
        portraitAsset: 'assets/images/portrait_mina.png',
        friendVoice: 'Bright',
        lastMessage: 'ignored',
        lastMessageAt: DateTime(2026),
        unreadCount: 1,
      ),
    );

    expect((result as Ok<Chat>).value.lastMessage, 'Hi!');
    expect(repo.cachedChat('mina')!.unreadCount, 1);
  });

  test('messages are cached only once loaded', () async {
    final repo = repository({
      'GET /api/chats/mina/messages': [
        message('m1', 'Hi!'),
        message('m2', 'Hello', isFromYou: true),
      ],
    });
    expect(repo.cachedMessages('mina'), isNull);

    await repo.getMessages('mina');

    expect(repo.cachedMessages('mina')!.map((m) => m.text), ['Hi!', 'Hello']);
  });

  test('sending stores your message and moves the chat up', () async {
    final repo = repository({
      'GET /api/chats': [minaChat, boChat],
      'GET /api/chats/mina/messages': [message('m1', 'Hi!')],
      'POST /api/chats/mina/messages': message(
        'm2',
        '',
        sentAt: '2026-10-26T10:00:00Z',
        isFromYou: true,
        postId: 'mina-1',
      ),
    });
    await repo.getChats();
    await repo.getMessages('mina');

    final result = await repo.sendMessage(
      chatId: 'mina',
      text: '',
      postId: 'mina-1',
    );

    expect(jsonDecode(sent.last.body), {
      'text': '',
      'postId': 'mina-1',
      'imageRefs': <String>[],
    });
    expect((result as Ok).value.postId, 'mina-1');
    expect(repo.cachedMessages('mina'), hasLength(2));
    expect(repo.cachedChats!.first.id, 'mina');
    expect(repo.cachedChats!.first.lastMessage, 'Replied to a post');
  });

  test(
    'photos are sent as paths and come back as the message\'s photos',
    () async {
      final repo = repository({
        'POST /api/chats/mina/messages': message(
          'm2',
          '',
          isFromYou: true,
          imageRefs: ['/phone/a.jpg', '/phone/b.jpg'],
        ),
      });

      final result = await repo.sendMessage(
        chatId: 'mina',
        text: '',
        imagePaths: const ['/phone/a.jpg', '/phone/b.jpg'],
      );

      expect(jsonDecode(sent.single.body)['imageRefs'], [
        '/phone/a.jpg',
        '/phone/b.jpg',
      ]);
      expect((result as Ok).value.imagePaths, ['/phone/a.jpg', '/phone/b.jpg']);
    },
  );

  test('a reply to photos uploads them, leaving out deleted ones', () async {
    final repo = repository({
      'GET /api/chats/mina/messages': [
        message('m1', 'Hi!'),
        message(
          'm2',
          'Guess what',
          isFromYou: true,
          imageRefs: ['/phone/a.jpg', '/phone/deleted.jpg'],
        ),
      ],
      'POST /api/chats/mina/reply': message('m3', 'A bike!'),
    });
    await repo.getMessages('mina');

    final result = await repo.getReply('mina');

    expect((result as Ok).value.text, 'A bike!');
    final upload = sent.last;
    expect(upload.headers['content-type'], startsWith('multipart/form-data'));
    final body = latin1.decode(upload.bodyBytes);
    expect('name="images"'.allMatches(body), hasLength(1));
    expect(body, contains('content-type: image/jpeg'));
    expect(body, contains('jpeg of /phone/a.jpg'));
    expect(body, isNot(contains('deleted')));
  });

  test('a reply to text is a plain request', () async {
    final repo = repository({
      'GET /api/chats/mina/messages': [message('m1', 'Hello', isFromYou: true)],
      'POST /api/chats/mina/reply': message('m2', 'Hey'),
    });
    await repo.getMessages('mina');

    await repo.getReply('mina');

    expect(sent.last.headers['content-type'], isNull);
  });

  test('a reply counts as unread until the chat is marked read', () async {
    final repo = repository({
      'GET /api/chats': [chat('mina', message('m1', 'Hi!'), unreadCount: 0)],
      'POST /api/chats/mina/reply': message(
        'm2',
        'Guess where I am',
        sentAt: '2026-10-26T10:00:00Z',
      ),
      'POST /api/chats/mina/read': null,
    });
    await repo.getChats();

    await repo.getReply('mina');
    expect(repo.cachedChat('mina')!.unreadCount, 1);
    expect(repo.cachedChat('mina')!.lastMessage, 'Guess where I am');

    var notified = 0;
    repo.addListener(() => notified++);
    final result = await repo.markRead('mina');

    expect(result, isA<Ok<void>>());
    expect(sent.last.url.path, '/api/chats/mina/read');
    expect(repo.cachedChat('mina')!.unreadCount, 0);
    expect(notified, 1);
  });

  test('a chat that does not exist is a ChatNotFoundException', () async {
    final repo = repository({});

    final result = await repo.getChat('vera');

    expect((result as Error).error, isA<ChatNotFoundException>());
  });

  test('requests while offline are OfflineExceptions', () async {
    final repo = ChatRepositoryRemote(
      apiService: ApiService(
        client: MockClient(
          (_) => throw http.ClientException('Connection refused'),
        ),
        baseUrl: Uri.parse('http://server.test'),
      ),
      portraitAssets: const {},
    );

    final send = await repo.sendMessage(chatId: 'mina', text: 'Hi');
    final reply = await repo.getReply('mina');

    expect((send as Error).error, isA<OfflineException>());
    expect((reply as Error).error, isA<OfflineException>());
  });

  group('voice calls', () {
    final pass = {
      'conversationToken': 'call-token',
      'prompt': 'You are Mina.',
      'firstMessage': "Hey, it's Mina!",
      'voiceId': 'voice-mina',
    };

    test('a call asks for the microphone, then connects with the server '
        'pass', () async {
      final repo = repository({'POST /api/chats/mina/call': pass});
      var notified = 0;
      repo.addListener(() => notified++);

      final result = await repo.startCall('mina');

      expect(result, isA<Ok<void>>());
      expect(voiceCalls.started, (
        conversationToken: 'call-token',
        prompt: 'You are Mina.',
        firstMessage: "Hey, it's Mina!",
        voiceId: 'voice-mina',
      ));
      expect(repo.isCallOnline, isTrue);
      expect(notified, 1);
    });

    test('without the microphone the call never starts', () async {
      final repo = repository({
        'POST /api/chats/mina/call': pass,
      }, microphone: false);

      final result = await repo.startCall('mina');

      expect((result as Error).error, isA<MicrophoneDeniedException>());
      expect(sent, isEmpty);
      expect(voiceCalls.started, isNull);
    });

    test('a call the server cannot set up never starts', () async {
      final repo = ChatRepositoryRemote(
        apiService: ApiService(
          client: MockClient(
            (_) async => http.Response('{"code":"call_unavailable"}', 503),
          ),
          baseUrl: Uri.parse('http://server.test'),
        ),
        portraitAssets: const {},
        voiceCallService: voiceCalls = _FakeVoiceCalls(),
      );

      final result = await repo.startCall('mina');

      expect(
        ((result as Error).error as ApiException).code,
        'call_unavailable',
      );
      expect(voiceCalls.started, isNull);
    });

    test('a dropped call goes offline and tells listeners', () async {
      final repo = repository({'POST /api/chats/mina/call': pass});
      await repo.startCall('mina');
      var notified = 0;
      repo.addListener(() => notified++);

      voiceCalls.drop();

      expect(repo.isCallOnline, isFalse);
      expect(notified, 1);
    });

    test('hanging up ends the call and saves its record', () async {
      final repo = repository({
        'GET /api/chats': [minaChat],
        'GET /api/chats/mina/messages': [message('m1', 'Hi!')],
        'POST /api/chats/mina/call': pass,
        'POST /api/chats/mina/calls': message(
          'm2',
          '',
          sentAt: '2026-10-26T10:00:00Z',
          isFromYou: true,
          callDurationSeconds: 151,
        ),
      });
      await repo.getChats();
      await repo.getMessages('mina');
      await repo.startCall('mina');

      final result = await repo.endCall(
        chatId: 'mina',
        duration: const Duration(minutes: 2, seconds: 31),
      );

      expect(voiceCalls.isConnected, isFalse);
      expect(jsonDecode(sent.last.body), {'durationSeconds': 151});
      expect(
        (result as Ok).value.callDuration,
        const Duration(minutes: 2, seconds: 31),
      );
      expect(repo.cachedMessages('mina')!.last.callDuration, isNotNull);
      expect(repo.cachedChat('mina')!.lastMessage, 'Voice call');
    });
  });
}
