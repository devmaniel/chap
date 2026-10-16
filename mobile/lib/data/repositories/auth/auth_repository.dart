import 'package:flutter/foundation.dart';

import '../../../utils/result.dart';

/// Owns the session. Notifies listeners whenever signed-in state changes.
abstract class AuthRepository extends ChangeNotifier {
  Future<bool> get isAuthenticated;

  Future<Result<void>> signIn({
    required String email,
    required String password,
  });

  Future<Result<void>> signUp({
    required String name,
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();
}

/// Email and password don't match an account. Never says which one is wrong.
final class WrongCredentialsException implements Exception {
  const WrongCredentialsException();
}

final class EmailTakenException implements Exception {
  const EmailTakenException();
}

final class OfflineException implements Exception {
  const OfflineException();
}
