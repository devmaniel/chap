import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/result.dart';

enum AuthFailure { wrongCredentials, emailTaken, offline, unknown }

/// What the form shows for a finished auth call. Null when it succeeded or
/// hasn't run.
AuthFailure? authFailureOf(Result<void>? result) => switch (result) {
  Error(error: WrongCredentialsException()) => AuthFailure.wrongCredentials,
  Error(error: EmailTakenException()) => AuthFailure.emailTaken,
  Error(error: OfflineException()) => AuthFailure.offline,
  Error() => AuthFailure.unknown,
  _ => null,
};
