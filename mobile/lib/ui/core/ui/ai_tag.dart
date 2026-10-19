import 'package:flutter/material.dart';

import '../themes/dimens.dart';

/// Small yellow label marking an AI character.
class AiTag extends StatelessWidget {
  const AiTag({super.key, this.label = 'AI'});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(Dimens.spaceXs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          label,
          maxLines: 1,
          style: TextStyle(
            color: colors.onTertiaryContainer,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.54,
          ),
        ),
      ),
    );
  }
}
