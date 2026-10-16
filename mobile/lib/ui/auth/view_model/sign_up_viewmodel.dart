import 'package:flutter/foundation.dart';

import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';
import 'auth_failure.dart';

class SignUpViewModel extends ChangeNotifier {
  SignUpViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository {
    signUp = Command0(_signUp);
  }

  static const minPasswordLength = 8;
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final AuthRepository _authRepository;

  late final Command0<void> signUp;

  String _name = '';
  String _email = '';
  String _password = '';

  bool get isPasswordRuleMet => _password.length >= minPasswordLength;

  bool get canSubmit =>
      _name.trim().isNotEmpty &&
      _emailPattern.hasMatch(_email.trim()) &&
      isPasswordRuleMet;

  AuthFailure? get failure => authFailureOf(signUp.result);

  void setName(String value) {
    _name = value;
    _onEdit();
  }

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
    if (signUp.error) signUp.clearResult();
    notifyListeners();
  }

  Future<Result<void>> _signUp() => _authRepository.signUp(
    name: _name.trim(),
    email: _email.trim(),
    password: _password,
  );
}
