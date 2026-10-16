import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/ui/primary_button.dart';
import '../view_model/auth_failure.dart';
import '../view_model/sign_in_viewmodel.dart';
import 'auth_form.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key, required this.viewModel});

  final SignInViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.signIn]),
      builder: (context, _) {
        final colors = Theme.of(context).colorScheme;
        final isBusy = viewModel.signIn.running;
        final failure = viewModel.failure;
        final isInvalid = failure == AuthFailure.wrongCredentials;
        final onSubmit = viewModel.canSubmit ? viewModel.signIn.execute : null;

        return AuthPage(
          title: 'Sign in',
          fields: [
            AuthField(
              hint: 'Email',
              enabled: !isBusy,
              isInvalid: isInvalid,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: viewModel.setEmail,
            ),
            AuthField(
              hint: 'Password',
              enabled: !isBusy,
              isInvalid: isInvalid,
              obscureText: true,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit?.call(),
              onChanged: viewModel.setPassword,
            ),
            if (failure != null) AuthNote.failure(failure, colors),
          ],
          submit: PrimaryButton(
            label: 'Sign in',
            loadingLabel: 'Signing in',
            isLoading: isBusy,
            onPressed: onSubmit,
          ),
          switchPrompt: 'New here?',
          switchLabel: 'CREATE ACCOUNT',
          onSwitch: isBusy ? null : () => context.go(Routes.signUp),
          termsLead: 'By signing in to Chap',
        );
      },
    );
  }
}
