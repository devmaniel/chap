import '../../../utils/result.dart';
import 'auth_repository.dart';

/// In-memory accounts for building the app before the server exists.
/// Nothing survives an app restart.
class AuthRepositoryLocal extends AuthRepository {
  AuthRepositoryLocal({
    this.latency = const Duration(milliseconds: 800),
    Map<String, String> passwordsByEmail = const {},
  }) : _passwordsByEmail = passwordsByEmail;

  /// Simulated round trip, so loading states are visible.
  final Duration latency;

  Map<String, String> _passwordsByEmail;
  String? _signedInEmail;
  bool _isSessionRestored = false;

  @override
  Future<bool> get isAuthenticated async {
    if (!_isSessionRestored) {
      await Future<void>.delayed(latency);
      _isSessionRestored = true;
    }
    return _signedInEmail != null;
  }

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final key = _normalize(email);
    if (_passwordsByEmail[key] != password) {
      return const Result.error(WrongCredentialsException());
    }
    _startSession(key);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(latency);
    final key = _normalize(email);
    if (_passwordsByEmail.containsKey(key)) {
      return const Result.error(EmailTakenException());
    }
    _passwordsByEmail = {..._passwordsByEmail, key: password};
    _startSession(key);
    return const Result.ok(null);
  }

  @override
  Future<Result<void>> signOut() async {
    _signedInEmail = null;
    notifyListeners();
    return const Result.ok(null);
  }

  void _startSession(String email) {
    _signedInEmail = email;
    notifyListeners();
  }

  String _normalize(String email) => email.trim().toLowerCase();
}
