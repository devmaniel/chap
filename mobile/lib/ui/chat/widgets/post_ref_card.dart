import 'package:flutter/material.dart';

import '../../../domain/models/post/post.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/illustrations.dart';
import '../../core/ui/app_icon.dart';

const _thumbSize = 44.0;
const _dotSize = 22.0;
const _dotGlyph = 14.0;

/// The friend's post a message replies to: thumbnail, whose it is, caption.
/// With [onRemove] it sits in the composer with an x; without, in a bubble.
class PostRefCard extends StatelessWidget {
  const PostRefCard({
    super.key,
    required this.post,
    required this.friendName,
    required this.portraitAsset,
    this.onRemove,
  });

  final Post post;
  final String friendName;
  final String portraitAsset;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isPicture = post.photos.isEmpty;
    final title = '$friendName’s ${isPicture ? 'profile picture' : 'photo'}';
    final card = Row(
      spacing: Dimens.spaceSm,
      children: [
        Semantics(
          image: true,
          label: title,
          excludeSemantics: true,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Dimens.radiusS),
            child: SizedBox.square(
              dimension: _thumbSize,
              child: isPicture
                  ? ColoredBox(
                      color: Illustrations.tone(post.characterId),
                      child: Image.asset(portraitAsset, fit: BoxFit.cover),
                    )
                  : DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: Illustrations.scene(post.photos.first.scene),
                      ),
                    ),
            ),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  letterSpacing: 0,
                  color: colors.onSurface,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                post.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  letterSpacing: 0,
                  color: colors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (onRemove case final onRemove?)
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove post',
            style: IconButton.styleFrom(
              fixedSize: const Size.square(Dimens.minTapTarget),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Container(
              width: _dotSize,
              height: _dotSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.onSurface,
                shape: BoxShape.circle,
              ),
              child: AppIcon(
                AppIconName.close,
                color: colors.surface,
                size: _dotGlyph,
              ),
            ),
          ),
      ],
    );
    if (onRemove != null) {
      return Padding(
        padding: const EdgeInsets.only(
          left: Dimens.spaceSm,
          top: Dimens.spaceSm,
        ),
        child: card,
      );
    }
    return Container(
      padding: const EdgeInsets.all(Dimens.spaceS),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: colors.outlineVariant,
          width: Dimens.borderWidth,
        ),
        borderRadius: BorderRadius.circular(Dimens.radiusS),
      ),
      child: card,
    );
  }
}
