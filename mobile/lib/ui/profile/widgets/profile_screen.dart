import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character/character.dart';
import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/illustrations.dart';
import '../../core/ui/ai_tag.dart';
import '../../core/ui/app_icon.dart';
import '../../core/ui/load_error.dart';
import '../../core/ui/raised_box.dart';
import '../../core/ui/skeleton.dart';
import '../view_model/profile_viewmodel.dart';
import 'post_card.dart';

/// A character's page: cover, bio, friends, then Posts, Photos or About.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.viewModel});

  static const _scrim = Color(0x993C3C3C);
  static const _sheetRadius = 28.0;

  final ProfileViewModel viewModel;

  void _openChat(BuildContext context, {String? postId}) =>
      context.push<void>(Routes.chat(viewModel.characterId, postId: postId));

  void _openPhoto(BuildContext context, String postId, int index) => context
      .push<void>(Routes.photo(viewModel.characterId, postId, index: index));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel.changes,
      builder: (context, _) {
        final character = viewModel.character;
        return Scaffold(
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SubHeader(title: character?.name ?? ''),
                Expanded(
                  child: switch (character) {
                    null when viewModel.load.error => ListView(
                      children: [
                        LoadError(
                          message: 'Couldn’t load this profile.',
                          onRetry: viewModel.load.execute,
                        ),
                      ],
                    ),
                    null => const _ProfileSkeleton(),
                    _ => _buildBody(context, character),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, Character character) {
    return ListView(
      children: [
        _Hero(
          character: character,
          friends: viewModel.friends,
          onOpenPicture: () =>
              _openPhoto(context, character.profilePicture.id, 0),
        ),
        _Actions(
          character: character,
          isAdding: viewModel.addFriend.running,
          onAddFriend: viewModel.addFriend.execute,
          onMessage: () => _openChat(context),
        ),
        _Tabs(current: viewModel.tab, onSelect: viewModel.selectTab),
        ...switch (viewModel.tab) {
          ProfileTab.posts => _posts(context, character),
          ProfileTab.photos => [_photos(context)],
          ProfileTab.about => _about(context, character),
        },
      ],
    );
  }

  List<Widget> _posts(BuildContext context, Character character) {
    final posts = viewModel.posts;
    if (posts.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.gutter,
            Dimens.spaceL,
            Dimens.gutter,
            Dimens.space3xl,
          ),
          child: Text(
            [
              '${character.name} hasn’t posted yet.',
              if (!character.isFriend)
                'Add ${character.name} to see new posts first.',
            ].join('\n'),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.7,
            ),
          ),
        ),
      ];
    }
    final now = DateTime.now();
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimens.gutter,
          0,
          Dimens.gutter,
          Dimens.space3xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: Dimens.spaceXl,
          children: [
            for (final post in posts)
              PostCard(
                post: post,
                character: character,
                meta: postMetaLabel(post, now),
                onLike: () => viewModel.toggleLike.execute(post),
                onReply: () => _openChat(context, postId: post.id),
                onOpenPhoto: (index) => _openPhoto(context, post.id, index),
              ),
          ],
        ),
      ),
    ];
  }

  Widget _photos(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: Dimens.spaceXs,
      crossAxisSpacing: Dimens.spaceXs,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        Dimens.gutter,
        0,
        Dimens.gutter,
        Dimens.space3xl,
      ),
      children: [
        for (final photo in viewModel.photos)
          PhotoTile(
            photo: photo.post.photos[photo.index],
            aspectRatio: 1,
            radius: Dimens.radiusS,
            onTap: () => _openPhoto(context, photo.post.id, photo.index),
          ),
      ],
    );
  }

  List<Widget> _about(BuildContext context, Character character) {
    final colors = Theme.of(context).colorScheme;
    final bodyStyle = TextStyle(
      color: colors.onSurface,
      fontSize: 14,
      fontWeight: FontWeight.w700,
      height: 1.6,
    );
    return [
      _Detail(
        children: [
          const _DetailTitle('A first hello'),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(Dimens.radius),
                bottomLeft: Radius.circular(Dimens.radius),
                bottomRight: Radius.circular(Dimens.radius),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.spaceChat,
                vertical: Dimens.spaceM,
              ),
              child: Text('“${character.firstHello}”', style: bodyStyle),
            ),
          ),
        ],
      ),
      _Detail(
        children: [
          const _DetailTitle('Interests'),
          Wrap(
            spacing: Dimens.spaceXs,
            runSpacing: Dimens.spaceXs,
            children: [
              for (final interest in character.interests) _Chip(interest),
            ],
          ),
        ],
      ),
      _Detail(
        children: [
          Row(
            spacing: Dimens.spaceChat,
            children: [
              Container(
                width: Dimens.minTapTarget,
                height: Dimens.minTapTarget,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(Dimens.spaceChat),
                ),
                child: AppIcon(
                  AppIconName.speaker,
                  color: colors.onPrimaryContainer,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    const _DetailTitle('Voice', bottom: 0),
                    Text(character.voice, style: bodyStyle),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      if (character.isFriend)
        _Detail(
          children: [
            RaisedBox(
              onTap: () => showModalBottomSheet<void>(
                context: context,
                backgroundColor: colors.surface,
                barrierColor: _scrim,
                showDragHandle: false,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_sheetRadius),
                  ),
                ),
                builder: (sheetContext) => _RemoveFriendSheet(
                  character: character,
                  onRemove: () async {
                    Navigator.of(sheetContext).pop();
                    await viewModel.removeFriend.execute();
                    if (!context.mounted || !viewModel.removeFriend.completed) {
                      return;
                    }
                    _showToast(context, 'Friend removed.');
                    context.pop();
                  },
                  onKeep: () => Navigator.of(sheetContext).pop(),
                ),
              ),
              radius: Dimens.radius,
              borderColor: colors.secondaryFixed,
              constraints: const BoxConstraints(minHeight: Dimens.minTapTarget),
              padding: const EdgeInsets.symmetric(
                horizontal: Dimens.spaceL,
                vertical: Dimens.spaceSm,
              ),
              child: Center(
                child: Text(
                  'REMOVE FRIEND',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.error,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.78,
                  ),
                ),
              ),
            ),
          ],
        ),
    ];
  }
}

/// Confirmation strip above the tab bar; outlives the route that shows it.
void _showToast(BuildContext context, String message) {
  final colors = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: colors.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Dimens.radius),
        side: BorderSide(color: colors.primaryFixed, width: Dimens.borderWidth),
      ),
      content: Text(
        message,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: Dimens.chatHeaderPadding,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant,
            width: Dimens.borderWidth,
          ),
        ),
      ),
      child: Row(
        spacing: Dimens.spaceS,
        children: [
          IconButton(
            tooltip: 'Go back',
            style: IconButton.styleFrom(
              minimumSize: const Size.square(Dimens.minTapTarget),
              maximumSize: const Size.square(Dimens.minTapTarget),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: EdgeInsets.zero,
            ),
            onPressed: () => context.pop(),
            icon: AppIcon(AppIconName.back, color: colors.onSurface),
          ),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cover with the portrait hanging off it, name, bio, home, friends.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.character,
    required this.friends,
    required this.onOpenPicture,
  });

  static const _bannerHeight = 128.0;
  static const _avatarSize = 112.0;
  static const _avatarOverhang = 60.0;
  static const _bannerGap = 68.0;
  static const _avatarRing = 4.0;
  static const _bioMaxWidth = 300.0;
  static const _miniAvatar = 24.0;
  static const _miniOverlap = 8.0;

  final Character character;
  final List<Character> friends;
  final VoidCallback onOpenPicture;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mutedStyle = TextStyle(
      color: colors.onSurfaceVariant,
      fontSize: 12,
      fontWeight: FontWeight.w800,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.spaceXl),
      child: Column(
        children: [
          SizedBox(
            height: _bannerHeight + _bannerGap,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  height: _bannerHeight,
                  decoration: BoxDecoration(
                    gradient: Illustrations.cover(character.id),
                  ),
                ),
                Positioned(
                  top: _bannerHeight + _avatarOverhang - _avatarSize,
                  child: Semantics(
                    button: true,
                    label: 'Open ${character.name}’s profile picture',
                    excludeSemantics: true,
                    child: GestureDetector(
                      onTap: onOpenPicture,
                      child: Container(
                        width: _avatarSize,
                        height: _avatarSize,
                        decoration: BoxDecoration(
                          color: Illustrations.tone(character.id),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.surface,
                            width: _avatarRing,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: colors.outlineVariant,
                              spreadRadius: Dimens.borderWidth,
                            ),
                            BoxShadow(
                              color: colors.outlineVariant,
                              spreadRadius: Dimens.borderWidth,
                              offset: const Offset(0, Dimens.buttonEdge),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            character.portraitAsset,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.gutter),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: Dimens.spaceS,
                  children: [
                    Flexible(
                      child: Text(
                        character.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const AiTag(label: 'AI CHARACTER'),
                  ],
                ),
                const SizedBox(height: Dimens.spaceXs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _bioMaxWidth),
                  child: Text(
                    character.bio,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: Dimens.spaceM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: Dimens.spaceL,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        spacing: Dimens.space2xs,
                        children: [
                          AppIcon(
                            AppIconName.compass,
                            size: 14,
                            color: colors.onSurfaceVariant,
                          ),
                          Flexible(
                            child: Text(
                              character.home,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: mutedStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${character.postCount} posts',
                      maxLines: 1,
                      style: mutedStyle,
                    ),
                  ],
                ),
                if (friends.isNotEmpty) ...[
                  const SizedBox(height: Dimens.spaceSm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: Dimens.spaceS,
                    children: [
                      SizedBox(
                        width:
                            _miniAvatar +
                            (friends.length - 1) * (_miniAvatar - _miniOverlap),
                        height: _miniAvatar,
                        child: Stack(
                          children: [
                            for (final (i, friend) in friends.indexed)
                              Positioned(
                                left: i * (_miniAvatar - _miniOverlap),
                                child: Container(
                                  width: _miniAvatar,
                                  height: _miniAvatar,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: colors.surface,
                                      width: Dimens.borderWidth,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Image.asset(
                                      friend.portraitAsset,
                                      fit: BoxFit.cover,
                                      excludeFromSemantics: true,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          friendsLabel([for (final f in friends) f.name]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: mutedStyle,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Add friend for a new character; Message and Call for a friend.
class _Actions extends StatelessWidget {
  const _Actions({
    required this.character,
    required this.isAdding,
    required this.onAddFriend,
    required this.onMessage,
  });

  static const _callWidth = 54.0;

  final Character character;
  final bool isAdding;
  final VoidCallback onAddFriend;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final primary = RaisedBox(
      onTap: character.isFriend
          ? onMessage
          : isAdding
          ? null
          : onAddFriend,
      isBordered: false,
      radius: Dimens.radius,
      color: colors.primary,
      edgeColor: colors.primaryFixedDim,
      constraints: const BoxConstraints(minHeight: Dimens.buttonMinHeight),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      child: isAdding
          ? Center(
              child: Semantics(
                liveRegion: true,
                label: 'Adding friend',
                child: SizedBox.square(
                  dimension: Dimens.spinner,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: colors.onPrimary,
                  ),
                ),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 9,
              children: [
                AppIcon(
                  character.isFriend ? AppIconName.chat : AppIconName.plus,
                  color: colors.onPrimary,
                ),
                Flexible(
                  child: Text(
                    character.isFriend ? 'MESSAGE' : 'ADD FRIEND',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.9,
                    ),
                  ),
                ),
              ],
            ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.gutter,
        0,
        Dimens.gutter,
        Dimens.gutter,
      ),
      child: Row(
        spacing: Dimens.spaceSm,
        children: [
          Expanded(child: primary),
          if (character.isFriend)
            Semantics(
              label: 'Call ${character.name}',
              excludeSemantics: true,
              child: RaisedBox(
                onTap: () {},
                radius: Dimens.radius,
                constraints: const BoxConstraints(
                  minWidth: _callWidth,
                  minHeight: Dimens.buttonMinHeight,
                ),
                child: Center(
                  widthFactor: 1,
                  child: AppIcon(
                    AppIconName.phone,
                    color: colors.onPrimaryContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.current, required this.onSelect});

  static const _labels = {
    ProfileTab.posts: 'POSTS',
    ProfileTab.photos: 'PHOTOS',
    ProfileTab.about: 'ABOUT',
  };

  final ProfileTab current;
  final ValueChanged<ProfileTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.gutter,
        0,
        Dimens.gutter,
        Dimens.gutter,
      ),
      child: Row(
        spacing: Dimens.spaceS,
        children: [
          for (final tab in ProfileTab.values)
            Expanded(
              child: Semantics(
                selected: tab == current,
                child: RaisedBox(
                  onTap: () => onSelect(tab),
                  color: tab == current
                      ? colors.primaryContainer
                      : colors.surface,
                  borderColor: tab == current ? colors.primaryFixed : null,
                  constraints: const BoxConstraints(
                    minHeight: Dimens.minTapTarget,
                  ),
                  child: Center(
                    child: Text(
                      _labels[tab]!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tab == current
                            ? colors.onPrimaryContainer
                            : colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.72,
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

/// Bordered card on the About tab.
class _Detail extends StatelessWidget {
  const _Detail({required this.children});

  static const _radius = 18.0;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.gutter,
        0,
        Dimens.gutter,
        Dimens.spaceL,
      ),
      child: RaisedBox(
        radius: _radius,
        padding: const EdgeInsets.all(Dimens.spaceL),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}

class _DetailTitle extends StatelessWidget {
  const _DetailTitle(this.text, {this.bottom = Dimens.spaceSm});

  final String text;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Text(
        text.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.96,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(Dimens.radiusS),
        border: Border.all(
          color: colors.outlineVariant,
          width: Dimens.borderWidth,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          height: 1.3,
        ),
      ),
    );
  }
}

/// Centered confirm: their face, one question, Remove in solid red,
/// Keep friend below.
class _RemoveFriendSheet extends StatelessWidget {
  const _RemoveFriendSheet({
    required this.character,
    required this.onRemove,
    required this.onKeep,
  });

  static const _avatar = 88.0;
  static const _textMaxWidth = 280.0;
  static const _dangerEdge = Color(0xFF7F1D1D);

  final Character character;
  final VoidCallback onRemove;
  final VoidCallback onKeep;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Dimens.gutter,
          Dimens.spaceM,
          Dimens.gutter,
          Dimens.space3xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: Dimens.galleryHandle,
              height: Dimens.spaceTiny,
              margin: const EdgeInsets.only(bottom: Dimens.spaceXl),
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(Dimens.spaceTiny),
              ),
            ),
            Container(
              width: _avatar,
              height: _avatar,
              margin: const EdgeInsets.only(bottom: Dimens.spaceChat),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Illustrations.tone(character.id),
                boxShadow: [
                  BoxShadow(color: colors.secondaryFixed, spreadRadius: 6),
                  BoxShadow(color: colors.surface, spreadRadius: 4),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  character.portraitAsset,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: Dimens.spaceS),
              child: Text(
                'Remove friend?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _textMaxWidth),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  'Remove ${character.name} from your friends? You can '
                  'discover this character again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.7,
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: Dimens.spaceChat,
              children: [
                RaisedBox(
                  onTap: onRemove,
                  isBordered: false,
                  radius: Dimens.radius,
                  color: colors.error,
                  edgeColor: _dangerEdge,
                  constraints: const BoxConstraints(
                    minHeight: Dimens.buttonMinHeight,
                  ),
                  child: Center(
                    child: Text(
                      'REMOVE',
                      maxLines: 1,
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.9,
                      ),
                    ),
                  ),
                ),
                RaisedBox(
                  onTap: onKeep,
                  radius: Dimens.radius,
                  constraints: const BoxConstraints(
                    minHeight: Dimens.buttonMinHeight,
                  ),
                  child: Center(
                    child: Text(
                      'KEEP FRIEND',
                      maxLines: 1,
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.78,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile-shaped placeholder: cover, avatar, name, bio, button, tabs.
class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label: 'Loading profile',
      excludeSemantics: true,
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 196,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(height: 128, color: colors.surfaceContainerLow),
                Positioned(
                  top: 76,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const SkeletonBox(
                      width: 104,
                      height: 104,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(
              Dimens.gutter,
              0,
              Dimens.gutter,
              Dimens.gutter,
            ),
            child: Column(
              spacing: Dimens.spaceS,
              children: [
                SkeletonBox(width: 140, height: 28),
                SkeletonBox(width: 260, height: 14),
                SkeletonBox(width: 200, height: 14),
                SizedBox(height: Dimens.spaceS),
                SkeletonBox(width: 150, height: 12),
                SizedBox(height: Dimens.spaceXl),
                SkeletonBox(height: Dimens.buttonMinHeight, radius: 16),
                SizedBox(height: Dimens.spaceL),
                SkeletonBox(height: Dimens.minTapTarget, radius: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
