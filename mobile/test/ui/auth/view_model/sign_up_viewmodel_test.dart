import 'package:app/data/repositories/auth/auth_repository_local.dart';
import 'package:app/ui/auth/view_model/auth_failure.dart';
import 'package:app/ui/auth/view_model/sign_up_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AuthRepositoryLocal repository;
  late SignUpViewModel viewModel;

  setUp(() {
    repository = AuthRepositoryLocal(latency: Duration.zero);
    viewModel = SignUpViewModel(authRepository: repository);
  });

  void fillValid() => viewModel
    ..setName('Jamie Dela Cruz')
    ..setEmail('jamie@example.com')
    ..setPassword('otterly42');

  test('password rule is met at 8 characters', () {
    viewModel.setPassword('1234567');
    expect(viewModel.isPasswordRuleMet, isFalse);

    viewModel.setPassword('12345678');
    expect(viewModel.isPasswordRuleMet, isTrue);
  });

  test('can submit only when every field is valid', () {
    fillValid();
    expect(viewModel.canSubmit, isTrue);

    viewModel.setEmail('jamie@example');
    expect(viewModel.canSubmit, isFalse);

    viewModel
      ..setEmail('jamie@example.com')
      ..setName('   ');
    expect(viewModel.canSubmit, isFalse);
  });

  test('valid details create the account and sign in', () async {
    fillValid();

    await viewModel.signUp.execute();

    expect(viewModel.failure, isNull);
    expect(await repository.isAuthenticated, isTrue);
  });

  test('a taken email shows email taken, editing clears it', () async {
    fillValid();
    await viewModel.signUp.execute();
    await repository.signOut();

    final second = SignUpViewModel(authRepository: repository)
      ..setName('Other')
      ..setEmail('jamie@example.com')
      ..setPassword('different1');
    await second.signUp.execute();
    expect(second.failure, AuthFailure.emailTaken);

    second.setEmail('other@example.com');
    expect(second.failure, isNull);
  });
}
