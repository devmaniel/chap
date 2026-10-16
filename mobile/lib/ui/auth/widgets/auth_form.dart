import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/themes/theme.dart';
import '../view_model/auth_failure.dart';

/// Page shared by sign in and sign up: title, fields, submit, switch link,
/// terms, and the otter peeking up from the bottom-right corner.
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
    required this.fields,
    required this.submit,
    required this.switchPrompt,
    required this.switchLabel,
    required this.onSwitch,
    required this.termsLead,
  });

  static const _termsMaxWidth = 196.0;
  static const _otterWidth = 176.0;
  static const _otterRight = -34.0;
  static const _otterBottom = -22.0;

  final String title;
  final List<Widget> fields;
  final Widget submit;
  final String switchPrompt;
  final String switchLabel;
  final VoidCallback? onSwitch;

  /// Start of the terms line, e.g. "By signing in to Chap".
  final String termsLead;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mutedStyle = TextStyle(
      color: colors.onSurfaceVariant,
      fontSize: 14,
      fontWeight: FontWeight.w700,
    );
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: Stack(
        children: [
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: Dimens.authPadding,
                  sliver: SliverFillRemaining(
                    hasScrollBody: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: Dimens.space2xl),
                        AutofillGroup(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: Dimens.spaceM,
                            children: fields,
                          ),
                        ),
                        const SizedBox(height: Dimens.spaceXl),
                        submit,
                        const SizedBox(height: Dimens.spaceM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(switchPrompt, style: mutedStyle),
                            ),
                            TextButton(
                              onPressed: onSwitch,
                              child: Text(switchLabel),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(height: Dimens.spaceXl),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: _termsMaxWidth,
                            ),
                            child: Text.rich(
                              TextSpan(
                                text: '$termsLead, you agree to our ',
                                children: [
                                  TextSpan(
                                    text: 'Terms',
                                    style: TextStyle(color: colors.onSurface),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(color: colors.onSurface),
                                  ),
                                  const TextSpan(text: '.'),
                                ],
                              ),
                              style: mutedStyle.copyWith(
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isKeyboardOpen)
            Positioned(
              right: _otterRight,
              bottom: _otterBottom,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/images/otter_peek.png',
                  width: _otterWidth,
                  excludeFromSemantics: true,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Placeholder-only text field. Red when [isInvalid]; locked when not [enabled].
/// With [obscureText], an eye button shows or hides the text.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.hint,
    required this.onChanged,
    required this.enabled,
    this.isInvalid = false,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String hint;
  final ValueChanged<String> onChanged;
  final bool enabled;
  final bool isInvalid;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  bool _isHidden = true;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final invalidBorder = widget.isInvalid
        ? AppTheme.fieldBorder(colors.error)
        : null;
    final suffix = [
      if (widget.obscureText)
        IconButton(
          onPressed: widget.enabled
              ? () => setState(() => _isHidden = !_isHidden)
              : null,
          tooltip: _isHidden ? 'Show password' : 'Hide password',
          color: colors.onSurfaceVariant,
          constraints: const BoxConstraints.tightFor(
            width: Dimens.minTapTarget,
            height: Dimens.minTapTarget,
          ),
          icon: Icon(
            _isHidden
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
    ];

    return TextField(
      onChanged: widget.onChanged,
      enabled: widget.enabled,
      obscureText: widget.obscureText && _isHidden,
      autocorrect: false,
      keyboardType: widget.keyboardType,
      autofillHints: widget.autofillHints,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      cursorColor: colors.primary,
      style: TextStyle(
        color: widget.enabled ? colors.onSurface : colors.onSurfaceVariant,
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
      decoration: InputDecoration(
        hintText: widget.hint,
        suffixIcon: suffix.isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: Dimens.spaceXs),
                child: Row(mainAxisSize: MainAxisSize.min, children: suffix),
              ),
        fillColor: widget.isInvalid ? colors.errorContainer : null,
        enabledBorder: invalidBorder,
        focusedBorder: invalidBorder,
      ),
    );
  }
}

/// One line under the fields: a rule hint, or what went wrong.
class AuthNote extends StatelessWidget {
  const AuthNote({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.isAlert = false,
  });

  /// The message for a failed sign in or sign up.
  factory AuthNote.failure(AuthFailure failure, ColorScheme colors) {
    final (text, icon) = switch (failure) {
      AuthFailure.wrongCredentials => (
        'Wrong email or password',
        Icons.error_outline_rounded,
      ),
      AuthFailure.emailTaken => (
        'This email already has an account',
        Icons.error_outline_rounded,
      ),
      AuthFailure.offline => ('No internet connection', Icons.wifi_off_rounded),
      AuthFailure.unknown => (
        'Something went wrong. Try again.',
        Icons.error_outline_rounded,
      ),
    };
    return AuthNote(text: text, icon: icon, color: colors.error, isAlert: true);
  }

  final String text;
  final IconData icon;
  final Color color;

  /// Announced by screen readers as soon as it appears.
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: isAlert,
      child: Row(
        children: [
          Icon(icon, size: Dimens.iconS, color: color),
          const SizedBox(width: Dimens.spaceXs),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
