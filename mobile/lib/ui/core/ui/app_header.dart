import 'package:flutter/material.dart';

import '../themes/dimens.dart';

/// Wordmark on the left, your initials on the right.
class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  static const _logoHeight = 28.0;

  /// The logo image is 5:2.
  static const _logoWidth = _logoHeight * 5 / 2;
  static const _ring = 34.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 9, 22, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Image.asset(
            'assets/images/wordmark.png',
            height: _logoHeight,
            width: _logoWidth,
            semanticLabel: 'Chaps',
          ),
          Semantics(
            button: true,
            label: 'Open your controls',
            excludeSemantics: true,
            child: InkWell(
              onTap: () {},
              customBorder: const CircleBorder(),
              child: SizedBox.square(
                dimension: Dimens.minTapTarget,
                child: Center(
                  child: Container(
                    width: _ring,
                    height: _ring,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.tertiaryContainer,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.tertiary,
                        width: Dimens.borderWidth,
                      ),
                    ),
                    child: Text(
                      'JD',
                      maxLines: 1,
                      style: TextStyle(
                        color: colors.onTertiaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
