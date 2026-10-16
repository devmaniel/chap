import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/ui/primary_button.dart';
import '../view_model/auth_failure.dart';
import '../view_model/sign_up_viewmodel.dart';
import 'auth_form.dart';

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key, required this.viewModel});

  final SignUpViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.signUp]),
      builder: (context, _) {
        final colors = Theme.of(context).colorScheme;
        final isBusy = viewModel.signUp.running;
        final failure = viewModel.failure;
        final onSubmit = viewModel.canSubmit ? viewModel.signUp.execute : null;

        return AuthPage(
          title: 'Create account',
          fields: [
            AuthField(
              hint: 'Name',
              enabled: !isBusy,
              keyboardType: TextInputType.name,
              autofillHints: const [AutofillHints.name],
              onChanged: viewModel.setName,
            ),
            AuthField(
              hint: 'Email',
              enabled: !isBusy,
              isInvalid: failure == AuthFailure.emailTaken,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              onChanged: viewModel.setEmail,
            ),
            AuthField(
              hint: 'Password',
              enabled: !isBusy,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onSubmit?.call(),
              onChanged: viewModel.setPassword,
            ),
            if (failure != null)
              AuthNote.failure(failure, colors)
            else
              AuthNote(
                text:
                    'Use ${SignUpViewModel.minPasswordLength} or more characters',
                icon: Icons.check_rounded,
                color: viewModel.isPasswordRuleMet
                    ? colors.onPrimaryContainer
                    : colors.onSurfaceVariant,
              ),
          ],
          submit: PrimaryButton(
            label: 'Create account',
            loadingLabel: 'Creating account',
            isLoading: isBusy,
            onPressed: onSubmit,
          ),
          switchPrompt: 'Have an account?',
          switchLabel: 'SIGN IN',
          onSwitch: isBusy ? null : () => context.go(Routes.signIn),
          termsLead: 'By signing up for Chap',
        );
      },
    );
  }
}
