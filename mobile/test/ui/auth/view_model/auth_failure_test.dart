import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/ui/auth/view_model/auth_failure.dart';
import 'package:app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps each result to the failure the form shows', () {
    expect(authFailureOf(null), isNull);
    expect(authFailureOf(const Result.ok(null)), isNull);
    expect(
      authFailureOf(const Result.error(WrongCredentialsException())),
      AuthFailure.wrongCredentials,
    );
    expect(
      authFailureOf(const Result.error(EmailTakenException())),
      AuthFailure.emailTaken,
    );
    expect(
      authFailureOf(const Result.error(OfflineException())),
      AuthFailure.offline,
    );
    expect(
      authFailureOf(Result.error(Exception('timeout'))),
      AuthFailure.unknown,
    );
  });
}
