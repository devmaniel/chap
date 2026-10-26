import 'dart:convert';

import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/auth/auth_repository_remote.dart';
import 'package:app/data/services/api_service.dart';
import 'package:app/utils/result.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const storage = FlutterSecureStorage();
  const session = '{"token":"t1","user":{"id":"u1","name":"Jamie"}}';

  late List<http.Request> sent;
  late ApiService api;

  /// A repository whose server answers every request with [respond].
  AuthRepositoryRemote repository(
    Future<http.Response> Function(http.Request request) respond, {
    String? storedToken,
  }) {
    FlutterSecureStorage.setMockInitialValues({'session_token': ?storedToken});
    sent = [];
    api = ApiService(
      client: MockClient((request) {
        sent.add(request);
        return respond(request);
      }),
      baseUrl: Uri.parse('http://server.test'),
    );
    return AuthRepositoryRemote(apiService: api);
  }

  Future<http.Response> reply(String body, int status) async =>
      http.Response(body, status);

  test('starts signed out without asking the server', () async {
    final auth = repository((_) => reply('', 500));

    expect(await auth.isAuthenticated, isFalse);
    expect(sent, isEmpty);
  });

  test('restores a stored session the server accepts', () async {
    final auth = repository((_) => reply('{}', 200), storedToken: 't1');

    expect(await auth.isAuthenticated, isTrue);
    expect(sent.single.url.path, '/api/me');
    expect(sent.single.headers['Authorization'], 'Bearer t1');
  });

  test('forgets a stored session the server rejects', () async {
    final auth = repository(
      (_) => reply('{"code":"unauthorized"}', 401),
      storedToken: 'expired',
    );

    expect(await auth.isAuthenticated, isFalse);
    expect(await storage.read(key: 'session_token'), isNull);
  });

  test('keeps a stored session while offline', () async {
    final auth = repository(
      (_) => throw http.ClientException('Connection refused'),
      storedToken: 't1',
    );

    expect(await auth.isAuthenticated, isTrue);
  });

  test('sign up stores the session and notifies', () async {
    final auth = repository((_) => reply(session, 201));
    var notified = 0;
    auth.addListener(() => notified++);

    final result = await auth.signUp(
      name: 'Jamie',
      email: 'jamie@example.com',
      password: 'otterly42',
    );

    expect(result, isA<Ok<void>>());
    expect(sent.single.url.path, '/api/auth/sign-up');
    expect(jsonDecode(sent.single.body), {
      'name': 'Jamie',
      'email': 'jamie@example.com',
      'password': 'otterly42',
    });
    expect(await auth.isAuthenticated, isTrue);
    expect(await storage.read(key: 'session_token'), 't1');
    expect(notified, 1);
  });

  test('sign up with a taken email is an EmailTakenException', () async {
    final auth = repository((_) => reply('{"code":"email_taken"}', 409));

    final result = await auth.signUp(
      name: 'Jamie',
      email: 'jamie@example.com',
      password: 'otterly42',
    );

    expect((result as Error<void>).error, isA<EmailTakenException>());
  });

  test('sign in with wrong credentials stays signed out', () async {
    final auth = repository((_) => reply('{"code":"wrong_credentials"}', 401));
    var notified = 0;
    auth.addListener(() => notified++);

    final result = await auth.signIn(
      email: 'jamie@example.com',
      password: 'nope',
    );

    expect((result as Error<void>).error, isA<WrongCredentialsException>());
    expect(await auth.isAuthenticated, isFalse);
    expect(notified, 0);
  });

  test('sign in while offline is an OfflineException', () async {
    final auth = repository(
      (_) => throw http.ClientException('Connection refused'),
    );

    final result = await auth.signIn(
      email: 'jamie@example.com',
      password: 'otterly42',
    );

    expect((result as Error<void>).error, isA<OfflineException>());
  });

  test('sign out forgets the session and notifies', () async {
    final auth = repository((_) => reply('{}', 200), storedToken: 't1');
    await auth.isAuthenticated;
    var notified = 0;
    auth.addListener(() => notified++);

    await auth.signOut();

    expect(await auth.isAuthenticated, isFalse);
    expect(await storage.read(key: 'session_token'), isNull);
    expect(notified, 1);
  });

  test('a rejected token on any later request signs out', () async {
    var accepted = true;
    final auth = repository(
      (_) =>
          accepted ? reply('{}', 200) : reply('{"code":"unauthorized"}', 401),
      storedToken: 't1',
    );
    await auth.isAuthenticated;
    var notified = 0;
    auth.addListener(() => notified++);

    accepted = false;
    await api.get('/api/chats');
    await pumpEventQueue();

    expect(await auth.isAuthenticated, isFalse);
    expect(await storage.read(key: 'session_token'), isNull);
    expect(notified, 1);
  });
}
