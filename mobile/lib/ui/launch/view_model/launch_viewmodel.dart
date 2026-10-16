import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';
import '../../../utils/result.dart';

/// Restores the session while the splash shows. The router's redirect then
/// picks home or sign in.
class LaunchViewModel {
  LaunchViewModel({required AuthRepository authRepository})
    : _authRepository = authRepository {
    load = Command0(_load)..execute();
  }

  final AuthRepository _authRepository;

  late final Command0<void> load;

  Future<Result<void>> _load() async {
    await _authRepository.isAuthenticated;
    return const Result.ok(null);
  }
}
