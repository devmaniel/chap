import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import 'auth_failure.dart';

class SignInViewModel extends ChangeNotifier {
  SignInViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository {
    signIn = Command0(_signIn);
  }

  final AuthRepository _authRepository;

  late final Command0<void> signIn;

  String _email = '';
  String _password = '';

  bool get canSubmit => _email.trim().isNotEmpty && _password.isNotEmpty;

  AuthFailure? get failure => authFailureOf(signIn.result);

  void setEmail(String value) {
    _email = value;
    _onEdit();
  }

  void setPassword(String value) {
    _password = value;
    _onEdit();
  }

  /// Editing after a failure clears it, so the red goes away.
  void _onEdit() {
    if (signIn.error) signIn.clearResult();
    notifyListeners();
  }

  Future<Result<void>> _signIn() =>
      _authRepository.signIn(email: _email.trim(), password: _password);
}
