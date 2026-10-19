import 'package:flutter/material.dart';

import '../themes/dimens.dart';
import 'raised_box.dart';

/// Unknown failure with nothing to show: red mark, one line, Retry.
class LoadError extends StatelessWidget {
  const LoadError({super.key, required this.message, required this.onRetry});

  static const _mark = 56.0;
  static const _textMaxWidth = 270.0;

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 32, 40, 28),
        child: Column(
          spacing: Dimens.spaceS,
          children: [
            Container(
              width: _mark,
              height: _mark,
              margin: const EdgeInsets.only(bottom: Dimens.spaceS),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: ExcludeSemantics(
                child: Text(
                  '!',
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _textMaxWidth),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: Dimens.spaceS),
            RaisedBox(
              onTap: onRetry,
              radius: Dimens.radius,
              constraints: const BoxConstraints(minHeight: Dimens.minTapTarget),
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.spaceL,
                vertical: Dimens.spaceSm,
              ),
              child: Text(
                'RETRY',
                maxLines: 1,
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.78,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
