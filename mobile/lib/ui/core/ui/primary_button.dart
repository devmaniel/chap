import 'package:flutter/material.dart';

import '../themes/dimens.dart';

/// Solid button standing on a darker edge. Grey and pressed flat when
/// [onPressed] is null; stays blue with a spinner while [isLoading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  /// Announced instead of [label] while loading.
  final String? loadingLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLive = onPressed != null || isLoading;
    final background = isLive ? colors.primary : colors.outlineVariant;
    final foreground = isLive ? colors.onPrimary : colors.onSurfaceVariant;
    final radius = BorderRadius.circular(Dimens.radius);

    return Padding(
      padding: EdgeInsets.only(
        top: isLive ? 0 : Dimens.buttonEdge,
        bottom: isLive ? Dimens.buttonEdge : 0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: [
            if (isLive)
              BoxShadow(
                color: colors.primaryFixedDim,
                offset: const Offset(0, Dimens.buttonEdge),
              ),
          ],
        ),
        child: Semantics(
          button: true,
          enabled: onPressed != null && !isLoading,
          child: Material(
            color: background,
            borderRadius: radius,
            child: InkWell(
              borderRadius: radius,
              onTap: isLoading ? null : onPressed,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: Dimens.buttonMinHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.spaceXl,
                    vertical: Dimens.spaceM,
                  ),
                  child: Center(
                    child: isLoading
                        ? Semantics(
                            liveRegion: true,
                            label: loadingLabel ?? label,
                            child: SizedBox.square(
                              dimension: Dimens.spinner,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: foreground,
                              ),
                            ),
                          )
                        : Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
