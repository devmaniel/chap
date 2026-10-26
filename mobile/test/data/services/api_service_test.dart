import 'dart:convert';

import 'package:app/data/services/api_service.dart';
import 'package:app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  final baseUrl = Uri.parse('http://server.test');

  ApiService service(MockClientHandler handler) =>
      ApiService(client: MockClient(handler), baseUrl: baseUrl);

  test('returns the decoded body', () async {
    late http.Request sent;
    final api = service((request) async {
      sent = request;
      return http.Response('{"status":"ok"}', 200);
    });

    final result = await api.get('/api/health');

    expect(sent.url, Uri.parse('http://server.test/api/health'));
    expect(sent.headers['Accept'], 'application/json');
    expect(result, isA<Ok<Object?>>());
    expect((result as Ok<Object?>).value, {'status': 'ok'});
  });

  test('sends the body as JSON', () async {
    late http.Request sent;
    final api = service((request) async {
      sent = request;
      return http.Response('', 204);
    });

    final result = await api.post('/api/things', {'name': 'Bo'});

    expect(sent.method, 'POST');
    expect(sent.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(sent.body), {'name': 'Bo'});
    expect((result as Ok<Object?>).value, isNull);
  });

  test('turns an error body into an ApiException', () async {
    final api = service(
      (_) async => http.Response(
        '{"code":"email_taken","message":"That email is taken."}',
        409,
      ),
    );

    final result = await api.post('/api/auth/sign-up', const {});

    final error = (result as Error<Object?>).error;
    expect(error, isA<ApiException>());
    expect((error as ApiException).statusCode, 409);
    expect(error.code, 'email_taken');
  });

  test('sends the token while one is set', () async {
    final sent = <http.Request>[];
    final api = service((request) async {
      sent.add(request);
      return http.Response('{}', 200);
    });

    await api.get('/api/me');
    api.token = 'abc';
    await api.get('/api/me');

    expect(sent.first.headers, isNot(contains('Authorization')));
    expect(sent.last.headers['Authorization'], 'Bearer abc');
  });

  test('reports a rejected token, but not a failed sign-in', () async {
    var rejected = 0;
    final api = service(
      (_) async => http.Response('{"code":"unauthorized"}', 401),
    )..onUnauthorized = () => rejected++;

    await api.post('/api/auth/sign-in', const {});
    expect(rejected, 0);

    api.token = 'expired';
    final result = await api.get('/api/me');

    expect(rejected, 1);
    expect(
      ((result as Error<Object?>).error as ApiException).code,
      'unauthorized',
    );
  });

  test('reports an unreachable server as a ClientException', () async {
    final api = service(
      (_) async => throw http.ClientException('Connection refused'),
    );

    final result = await api.get('/api/health');

    expect((result as Error<Object?>).error, isA<http.ClientException>());
  });
}
