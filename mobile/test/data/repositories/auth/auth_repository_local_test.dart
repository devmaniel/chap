import 'package:app/data/repositories/auth/auth_repository.dart';
import 'package:app/data/repositories/auth/auth_repository_local.dart';
import 'package:app/utils/result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuthRepositoryLocal repository;

  setUp(() => repository = AuthRepositoryLocal(latency: Duration.zero));

  Future<Result<void>> signUpJamie() => repository.signUp(
    name: 'Jamie',
    email: 'jamie@example.com',
    password: 'otterly42',
  );

  test('starts signed out', () async {
    expect(await repository.isAuthenticated, isFalse);
  });

  test('sign up starts a session and notifies', () async {
    var notified = 0;
    repository.addListener(() => notified++);

    final result = await signUpJamie();

    expect(result, isA<Ok<void>>());
    expect(await repository.isAuthenticated, isTrue);
    expect(notified, 1);
  });

  test('sign up with a taken email fails, ignoring case and spaces', () async {
    await signUpJamie();

    final result = await repository.signUp(
      name: 'Other',
      email: '  JAMIE@example.com ',
      password: 'whatever1',
    );

    expect(result, isA<Error<void>>());
    expect((result as Error<void>).error, isA<EmailTakenException>());
  });

  test('sign in with the right password starts a session', () async {
    await signUpJamie();
    await repository.signOut();

    final result = await repository.signIn(
      email: 'Jamie@Example.com',
      password: 'otterly42',
    );

    expect(result, isA<Ok<void>>());
    expect(await repository.isAuthenticated, isTrue);
  });

  test('sign in with a wrong password or unknown email fails', () async {
    await signUpJamie();
    await repository.signOut();

    final wrongPassword = await repository.signIn(
      email: 'jamie@example.com',
      password: 'nope',
    );
    final unknownEmail = await repository.signIn(
      email: 'nobody@example.com',
      password: 'otterly42',
    );

    for (final result in [wrongPassword, unknownEmail]) {
      expect((result as Error<void>).error, isA<WrongCredentialsException>());
    }
    expect(await repository.isAuthenticated, isFalse);
  });

  test('sign out ends the session and notifies', () async {
    await signUpJamie();
    var notified = 0;
    repository.addListener(() => notified++);

    await repository.signOut();

    expect(await repository.isAuthenticated, isFalse);
    expect(notified, 1);
  });
}
