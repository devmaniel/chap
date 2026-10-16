import '../../../data/repositories/auth/auth_repository.dart';
import '../../../utils/command.dart';

class HomeViewModel {
  HomeViewModel({required AuthRepository authRepository}) {
    signOut = Command0(authRepository.signOut);
  }

  late final Command0<void> signOut;
}
