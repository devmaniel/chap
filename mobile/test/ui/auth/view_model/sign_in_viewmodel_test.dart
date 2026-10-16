import 'package:app/data/repositories/auth/auth_repository_local.dart';
import 'package:app/ui/auth/view_model/auth_failure.dart';
import 'package:app/ui/auth/view_model/sign_in_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuthRepositoryLocal repository;
  late SignInViewModel viewModel;

  setUp(() async {
    repository = AuthRepositoryLocal(latency: Duration.zero);
    await repository.signUp(
      name: 'Jamie',
      email: 'jamie@example.com',
      password: 'otterly42',
    );
    await repository.signOut();
    viewModel = SignInViewModel(authRepository: repository);
  });

  test('can submit only once both fields have text', () {
    expect(viewModel.canSubmit, isFalse);

    viewModel.setEmail('jamie@example.com');
    expect(viewModel.canSubmit, isFalse);

    viewModel.setPassword('x');
    expect(viewModel.canSubmit, isTrue);
  });

  test('right credentials sign in with no failure', () async {
    viewModel
      ..setEmail(' jamie@example.com ')
      ..setPassword('otterly42');

    await viewModel.signIn.execute();

    expect(viewModel.signIn.completed, isTrue);
    expect(viewModel.failure, isNull);
    expect(await repository.isAuthenticated, isTrue);
  });

  test('wrong password shows wrong credentials, editing clears it', () async {
    viewModel
      ..setEmail('jamie@example.com')
      ..setPassword('nope');

    await viewModel.signIn.execute();
    expect(viewModel.failure, AuthFailure.wrongCredentials);

    viewModel.setPassword('nope2');
    expect(viewModel.failure, isNull);
  });
}
