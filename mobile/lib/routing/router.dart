import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../data/repositories/auth/auth_repository.dart';
import '../ui/auth/view_model/sign_in_viewmodel.dart';
import '../ui/auth/view_model/sign_up_viewmodel.dart';
import '../ui/auth/widgets/sign_in_screen.dart';
import '../ui/auth/widgets/sign_up_screen.dart';
import '../ui/call/view_model/call_viewmodel.dart';
import '../ui/call/widgets/call_screen.dart';
import '../ui/chat/view_model/chat_viewmodel.dart';
import '../ui/chat/widgets/chat_screen.dart';
import '../ui/chats/view_model/chats_viewmodel.dart';
import '../ui/chats/widgets/chats_screen.dart';
import '../ui/discover/view_model/discover_viewmodel.dart';
import '../ui/discover/widgets/discover_screen.dart';
import '../ui/friends/view_model/friends_viewmodel.dart';
import '../ui/friends/widgets/friends_screen.dart';
import '../ui/launch/view_model/launch_viewmodel.dart';
import '../ui/launch/widgets/launch_screen.dart';
import '../ui/profile/view_model/photo_viewer_viewmodel.dart';
import '../ui/profile/view_model/profile_viewmodel.dart';
import '../ui/profile/widgets/photo_viewer_screen.dart';
import '../ui/profile/widgets/profile_screen.dart';
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
      pageBuilder: (context, state) => NoTransitionPage(
        child: ChatsScreen(viewModel: context.read<ChatsViewModel>()),
      ),
      routes: [
        GoRoute(
          path: 'chat/:id',
          builder: (context, state) => ChatScreen(
            key: state.pageKey,
            replyToPostId: state.uri.queryParameters['post'],
            viewModel: context.read<Map<String, ChatViewModel>>().putIfAbsent(
              state.pathParameters['id']!,
              () => ChatViewModel(
                chatId: state.pathParameters['id']!,
                chatRepository: context.read(),
                characterRepository: context.read(),
              ),
            ),
          ),
          routes: [
            GoRoute(
              path: 'call',
              builder: (context, state) => CallScreen(
                viewModel: CallViewModel(
                  chatId: state.pathParameters['id']!,
                  chatRepository: context.read(),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.discover,
      pageBuilder: (context, state) => NoTransitionPage(
        child: DiscoverScreen(viewModel: context.read<DiscoverViewModel>()),
      ),
      routes: [
        GoRoute(
          path: ':characterId',
          builder: _profile,
          routes: [
            GoRoute(
              path: 'photo/:postId',
              builder: (context, state) => PhotoViewerScreen(
                viewModel: PhotoViewerViewModel(
                  characterId: state.pathParameters['characterId']!,
                  postId: state.pathParameters['postId']!,
                  initialIndex:
                      int.tryParse(state.uri.queryParameters['index'] ?? '') ??
                      0,
                  characterRepository: context.read(),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.friends,
      pageBuilder: (context, state) => NoTransitionPage(
        child: FriendsScreen(viewModel: context.read<FriendsViewModel>()),
      ),
      routes: [GoRoute(path: ':characterId', builder: _profile)],
    ),
  ],
);

/// One profile view model per character, shared by Discover and Friends.
Widget _profile(BuildContext context, GoRouterState state) {
  final characterId = state.pathParameters['characterId']!;
  return ProfileScreen(
    viewModel: context.read<Map<String, ProfileViewModel>>().putIfAbsent(
      characterId,
      () => ProfileViewModel(
        characterId: characterId,
        characterRepository: context.read(),
        chatRepository: context.read(),
      ),
    ),
  );
}

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
