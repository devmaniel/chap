import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../ui/auth/view_model/sign_in_viewmodel.dart';
import '../ui/auth/view_model/sign_up_viewmodel.dart';
import '../ui/auth/widgets/sign_in_screen.dart';
import '../ui/auth/widgets/sign_up_screen.dart';
import '../ui/chat/view_model/chat_viewmodel.dart';
import '../ui/chat/widgets/chat_screen.dart';
import '../ui/chats/view_model/chats_viewmodel.dart';
import '../ui/chats/widgets/chats_screen.dart';
import '../ui/launch/view_model/launch_viewmodel.dart';
import '../ui/launch/widgets/launch_screen.dart';
import 'routes.dart';

const _authRoutes = {Routes.signIn, Routes.signUp};

/// Re-runs [_redirect] whenever the session changes, so sign in, sign up and
/// sign out navigate on their own.
GoRouter router(AuthRepository authRepository) => GoRouter(
  initialLocation: Routes.launch,
  refreshListenable: authRepository,
  redirect: (context, state) => _redirect(authRepository, state),
  routes: [
    GoRoute(
      path: Routes.launch,
      builder: (context, state) => LaunchScreen(
        viewModel: LaunchViewModel(authRepository: context.read()),
      ),
    ),
    GoRoute(
      path: Routes.signIn,
      builder: (context, state) => SignInScreen(
        viewModel: SignInViewModel(authRepository: context.read()),
      ),
    ),
    GoRoute(
      path: Routes.signUp,
      builder: (context, state) => SignUpScreen(
        viewModel: SignUpViewModel(authRepository: context.read()),
      ),
    ),
    GoRoute(
      path: Routes.chats,
      builder: (context, state) =>
          ChatsScreen(viewModel: context.read<ChatsViewModel>()),
      routes: [
        GoRoute(
          path: 'chat/:id',
          builder: (context, state) => ChatScreen(
            key: state.pageKey,
            viewModel: context.read<Map<String, ChatViewModel>>().putIfAbsent(
              state.pathParameters['id']!,
              () => ChatViewModel(
                chatId: state.pathParameters['id']!,
                chatRepository: context.read(),
              ),
            ),
          ),
        ),
      ],
    ),
  ],
);

Future<String?> _redirect(
  AuthRepository authRepository,
  GoRouterState state,
) async {
  final location = state.matchedLocation;
  if (location == Routes.launch) return null;
  final isOnAuthRoute = _authRoutes.contains(location);
  if (!await authRepository.isAuthenticated) {
    return isOnAuthRoute ? null : Routes.signIn;
  }
  return isOnAuthRoute ? Routes.chats : null;
}
