import 'package:flutter/material.dart';

import '../../../domain/models/character/character.dart';
import '../../../domain/models/post/post.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/illustrations.dart';
import '../../core/ui/ai_tag.dart';
import '../../core/ui/app_icon.dart';
import '../../core/ui/raised_box.dart';

double photoAspectRatio(PhotoShape shape) => switch (shape) {
  PhotoShape.landscape => 4 / 3,
  PhotoShape.portrait => 4 / 5,
  PhotoShape.wide => 16 / 9,
};

/// One timeline post: who and when, text, photos, likes, actions.
class PostCard extends StatelessWidget {
  const PostCard({
    super.key,
    required this.post,
    required this.character,
    required this.meta,
    required this.onLike,
    required this.onReply,
    required this.onOpenPhoto,
  });

  static const _radius = 20.0;

  final Post post;
  final Character character;

  /// "2h · Old town".
  final String meta;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final ValueChanged<int> onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return RaisedBox(
      radius: _radius,
      padding: const EdgeInsets.fromLTRB(
        Dimens.spaceL,
        Dimens.spaceL,
        Dimens.spaceL,
        Dimens.spaceS,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PostHead(character: character, meta: meta),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Dimens.spaceM),
            child: Text(
              post.text,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.6,
              ),
            ),
          ),
          if (post.photos.isNotEmpty)
            _PostPhotos(photos: post.photos, onOpen: onOpenPhoto),
          PostStats(likeCount: post.likeCount),
          PostActions(isLiked: post.isLiked, onLike: onLike, onReply: onReply),
        ],
      ),
    );
  }
}

/// Avatar, name with AI tag, and the meta line under it.
class PostHead extends StatelessWidget {
  const PostHead({
    super.key,
    required this.character,
    required this.meta,
    this.isOnDark = false,
  });

  final Character character;
  final String meta;
  final bool isOnDark;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      spacing: Dimens.spaceSm,
      children: [
        ClipOval(
          child: Image.asset(
            character.portraitAsset,
            width: Dimens.chatAvatar,
            height: Dimens.chatAvatar,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2,
            children: [
              Row(
                spacing: Dimens.spaceXs,
                children: [
                  Flexible(
                    child: Text(
                      character.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isOnDark ? ViewerColors.ink : colors.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const AiTag(),
                ],
              ),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isOnDark
                      ? ViewerColors.muted
                      : colors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One photo: its shape when alone, side by side when two portraits,
/// otherwise stacked; three or more make a collage with a "+N" on the last.
class _PostPhotos extends StatelessWidget {
  const _PostPhotos({required this.photos, required this.onOpen});

  static const _gap = 6.0;

  final List<PostPhoto> photos;
  final ValueChanged<int> onOpen;

  Widget _tile(int index, double aspectRatio, {int more = 0}) => PhotoTile(
    photo: photos[index],
    aspectRatio: aspectRatio,
    more: more,
    onTap: () => onOpen(index),
  );

  @override
  Widget build(BuildContext context) {
    if (photos.length == 1) {
      return _tile(0, photoAspectRatio(photos.first.shape));
    }
    if (photos.length == 2 &&
        photos.every((photo) => photo.shape == PhotoShape.portrait)) {
      return Row(
        spacing: _gap,
        children: [
          Expanded(child: _tile(0, 4 / 5)),
          Expanded(child: _tile(1, 4 / 5)),
        ],
      );
    }
    if (photos.length == 2) {
      return Column(
        spacing: _gap,
        children: [
          for (var i = 0; i < 2; i++)
            _tile(i, photoAspectRatio(photos[i].shape)),
        ],
      );
    }
    return Column(
      spacing: _gap,
      children: [
        _tile(0, 4 / 3),
        Row(
          spacing: _gap,
          children: [
            Expanded(child: _tile(1, 1)),
            Expanded(child: _tile(2, 1, more: photos.length - 3)),
          ],
        ),
      ],
    );
  }
}

/// A photo that opens the viewer; [more] hidden photos show as "+N" on it.
class PhotoTile extends StatelessWidget {
  const PhotoTile({
    super.key,
    required this.photo,
    required this.aspectRatio,
    required this.onTap,
    this.more = 0,
    this.radius = 14,
  });

  static const _moreScrim = Color(0x8C3C3C3C);

  final PostPhoto photo;
  final double aspectRatio;
  final VoidCallback onTap;
  final int more;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final label = more > 0
        ? 'Photo: ${photo.description}, and $more more photos'
        : 'Photo: ${photo.description}';
    return Semantics(
      button: true,
      image: true,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: Illustrations.scene(photo.scene),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: more > 0
                ? DecoratedBox(
                    decoration: BoxDecoration(
                      color: _moreScrim,
                      borderRadius: BorderRadius.circular(radius),
                    ),
                    child: Center(
                      child: Text(
                        '+$more',
                        maxLines: 1,
                        style: const TextStyle(
                          color: ViewerColors.ink,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Filled heart and the like count, over a hairline.
class PostStats extends StatelessWidget {
  const PostStats({super.key, required this.likeCount, this.isOnDark = false});

  final int likeCount;
  final bool isOnDark;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.only(
        top: Dimens.spaceM,
        bottom: Dimens.spaceSm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isOnDark ? ViewerColors.line : colors.outlineVariant,
            width: Dimens.borderWidth,
          ),
        ),
      ),
      child: Row(
        spacing: Dimens.spaceTiny,
        children: [
          AppIcon(
            AppIconName.heartFilled,
            size: 16,
            color: isOnDark ? ViewerColors.like : colors.error,
          ),
          Text(
            '$likeCount',
            semanticsLabel: '$likeCount likes',
            style: TextStyle(
              color: isOnDark ? ViewerColors.muted : colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Like and Reply in chat.
class PostActions extends StatelessWidget {
  const PostActions({
    super.key,
    required this.isLiked,
    required this.onLike,
    required this.onReply,
    this.isOnDark = false,
  });

  final bool isLiked;
  final VoidCallback onLike;
  final VoidCallback onReply;
  final bool isOnDark;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final idle = isOnDark ? ViewerColors.ink : colors.onSurfaceVariant;
    final liked = isOnDark ? ViewerColors.like : colors.error;
    return Padding(
      padding: const EdgeInsets.only(top: Dimens.spaceS),
      child: Row(
        spacing: Dimens.spaceS,
        children: [
          Expanded(
            child: Semantics(
              toggled: isLiked,
              child: _Action(
                icon: isLiked ? AppIconName.heartFilled : AppIconName.heart,
                label: isLiked ? 'Liked' : 'Like',
                color: isLiked ? liked : idle,
                onTap: onLike,
              ),
            ),
          ),
          Expanded(
            child: _Action(
              icon: AppIconName.send,
              label: 'Reply in chat',
              color: idle,
              onTap: onReply,
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final AppIconName icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimens.radiusS),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Dimens.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Dimens.space2xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: Dimens.spaceTiny,
            children: [
              AppIcon(icon, size: Dimens.iconS, color: color),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
