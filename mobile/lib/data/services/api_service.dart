import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../utils/result.dart';

/// A request the server answered with an error: its HTTP status and error
/// `code`, e.g. 409 `email_taken`.
final class ApiException implements Exception {
  const ApiException(this.statusCode, this.code);

  final int statusCode;
  final String code;

  @override
  String toString() => 'ApiException($statusCode, $code)';
}

/// Talks JSON to the Chap server and returns decoded bodies. A server that
/// can't be reached comes back as an [http.ClientException] error.
///
/// The auth repository owns the session: it sets [token] and listens through
/// [onUnauthorized].
class ApiService {
  ApiService({http.Client? client, Uri? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? defaultBaseUrl;

  /// `--dart-define=API_BASE_URL=http://<laptop-ip>:8080` on a real phone;
  /// otherwise the simulator's or emulator's route to this computer.
  static Uri get defaultBaseUrl {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return Uri.parse(configured);
    return Uri.parse(
      Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080',
    );
  }

  final http.Client _client;
  final Uri _baseUrl;

  /// Sent as `Authorization: Bearer` on every request while set.
  String? token;

  /// Called when the server rejects [token], e.g. because it expired.
  void Function()? onUnauthorized;

  Future<Result<Object?>> get(String path) => _send(_json('GET', path));

  Future<Result<Object?>> post(String path, [Object? body]) =>
      _send(_json('POST', path, body));

  Future<Result<Object?>> put(String path, [Object? body]) =>
      _send(_json('PUT', path, body));

  Future<Result<Object?>> delete(String path) => _send(_json('DELETE', path));

  /// Posts [jpegs] as multipart `images` parts.
  Future<Result<Object?>> postImages(String path, List<Uint8List> jpegs) =>
      _send(
        http.MultipartRequest('POST', _baseUrl.resolve(path))
          ..files.addAll([
            for (final (index, bytes) in jpegs.indexed)
              http.MultipartFile.fromBytes(
                'images',
                bytes,
                filename: 'photo-$index.jpg',
                contentType: MediaType('image', 'jpeg'),
              ),
          ]),
      );

  http.Request _json(String method, String path, [Object? body]) {
    final request = http.Request(method, _baseUrl.resolve(path));
    if (body != null) {
      request
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);
    }
    return request;
  }

  Future<Result<Object?>> _send(http.BaseRequest request) async {
    final sentToken = token;
    request.headers['Accept'] = 'application/json';
    if (sentToken != null) {
      request.headers['Authorization'] = 'Bearer $sentToken';
    }
    try {
      final response = await http.Response.fromStream(
        await _client.send(request),
      );
      final decoded = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode == 401 && sentToken != null) {
        onUnauthorized?.call();
      }
      if (response.statusCode >= 400) {
        final code = switch (decoded) {
          {'code': final String code} => code,
          _ => 'unknown',
        };
        return Result.error(ApiException(response.statusCode, code));
      }
      return Result.ok(decoded);
    } on http.ClientException catch (error) {
      return Result.error(error);
    } on FormatException catch (error) {
      return Result.error(error);
    }
  }
}
