import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../../../utils/result.dart';
import '../../services/api_service.dart';
import 'auth_repository.dart';

/// Accounts on the Chap server. The session token is kept in secure storage,
/// so the user stays signed in across app restarts.
class AuthRepositoryRemote extends AuthRepository {
  AuthRepositoryRemote({
    required ApiService apiService,
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _api = apiService,
       _storage = storage {
    _api.onUnauthorized = _endSession;
  }

  static const _tokenKey = 'session_token';

  final ApiService _api;
  final FlutterSecureStorage _storage;

  late final Future<void> _restored = _restoreSession();

  @override
  Future<bool> get isAuthenticated async {
    await _restored;
    return _api.token != null;
  }

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) => _startSession('/api/auth/sign-in', {
    'email': email,
    'password': password,
  });

  @override
  Future<Result<void>> signUp({
    required String name,
    required String email,
    required String password,
  }) => _startSession('/api/auth/sign-up', {
    'name': name,
    'email': email,
    'password': password,
  });

  @override
  Future<Result<void>> signOut() async {
    await _endSession();
    return const Result.ok(null);
  }

  /// Checks a stored token with the server. A rejected token ends the session
  /// through [ApiService.onUnauthorized]; when offline, the token is kept so
  /// the app still opens signed in.
  Future<void> _restoreSession() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return;
    _api.token = token;
    await _api.get('/api/me');
  }

  Future<Result<void>> _startSession(
    String path,
    Map<String, String> body,
  ) async {
    switch (await _api.post(path, body)) {
      case Ok(value: {'token': final String token}):
        await _storage.write(key: _tokenKey, value: token);
        _api.token = token;
        notifyListeners();
        return const Result.ok(null);
      case Ok():
        return const Result.error(FormatException('No token in response'));
      case Error(error: ApiException(code: 'email_taken')):
        return const Result.error(EmailTakenException());
      case Error(error: ApiException(code: 'wrong_credentials')):
        return const Result.error(WrongCredentialsException());
      case Error(error: http.ClientException()):
        return const Result.error(OfflineException());
      case Error(:final error):
        return Result.error(error);
    }
  }

  Future<void> _endSession() async {
    _api.token = null;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }
}
