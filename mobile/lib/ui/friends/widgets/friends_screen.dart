import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/models/character/character.dart';
import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/illustrations.dart';
import '../../core/ui/ai_tag.dart';
import '../../core/ui/app_header.dart';
import '../../core/ui/app_icon.dart';
import '../../core/ui/bottom_nav.dart';
import '../../core/ui/load_error.dart';
import '../../core/ui/skeleton.dart';
import '../view_model/friends_viewmodel.dart';

/// A card per friend; tap opens their profile.
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key, required this.viewModel});

  static const _skeletonCards = 3;

  final FriendsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel.changes,
      builder: (context, _) => Scaffold(
        bottomNavigationBar: BottomNav(
          current: AppTab.friends,
          onSelect: (tab) => switch (tab) {
            AppTab.chats => context.go(Routes.chats),
            AppTab.discover => context.go(Routes.discover),
            AppTab.friends => null,
          },
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppHeader(),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final friends = viewModel.friends;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.gutter,
            14,
            Dimens.gutter,
            Dimens.spaceTiny,
          ),
          child: Text(
            'Friends',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.onSurface,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.gutter,
            3,
            Dimens.gutter,
            Dimens.spaceXl,
          ),
          child: Text(
            'A few familiar personalities. All your own.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.6,
            ),
          ),
        ),
        if (viewModel.load.running)
          Semantics(
            liveRegion: true,
            label: 'Loading friends',
            excludeSemantics: true,
            child: Column(
              children: [
                for (var i = 0; i < _skeletonCards; i++) const _SkeletonCard(),
              ],
            ),
          )
        else if (viewModel.load.error)
          LoadError(
            message: 'Couldn’t load friends.',
            onRetry: viewModel.load.execute,
          )
        else ...[
          _SectionLabel(count: friends.length),
          for (final friend in friends)
            _FriendCard(
              friend: friend,
              onTap: () => context.push<void>(Routes.friend(friend.id)),
            ),
          Padding(
            padding: const EdgeInsets.all(Dimens.gutter),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: Dimens.spaceXs,
              children: [
                AppIcon(
                  AppIconName.spark,
                  color: colors.onSurfaceVariant,
                  size: Dimens.iconS,
                ),
                Flexible(
                  child: Text(
                    'Fictional friends. Room to be yourself.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = TextStyle(
      color: colors.onSurfaceVariant,
      fontSize: 12,
      fontWeight: FontWeight.w900,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimens.gutter, 0, Dimens.gutter, 2),
      child: Row(
        spacing: Dimens.spaceM,
        children: [
          Expanded(
            child: Text(
              'YOUR FRIENDS',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style.copyWith(letterSpacing: 0.96),
            ),
          ),
          Text(
            friendCountLabel(count),
            maxLines: 1,
            style: style.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend, required this.onTap});

  static const _avatar = 72.0;
  static const _tagRadius = 10.0;

  final Character friend;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tone = Illustrations.tone(friend.id);
    return Semantics(
      button: true,
      label: '${friend.name}, AI character. Open profile',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Dimens.gutter,
            vertical: Dimens.spaceM,
          ),
          child: Row(
            spacing: 14,
            children: [
              ClipOval(
                child: Container(
                  width: _avatar,
                  height: _avatar,
                  color: tone,
                  child: Image.asset(
                    friend.portraitAsset,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Dimens.spaceTiny,
                  children: [
                    Row(
                      spacing: Dimens.spaceXs,
                      children: [
                        Flexible(
                          child: Text(
                            friend.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const AiTag(),
                      ],
                    ),
                    Text(
                      friend.tagline,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                    Wrap(
                      spacing: Dimens.spaceTiny,
                      runSpacing: Dimens.spaceTiny,
                      children: [
                        for (final interest in friend.interests)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: tone,
                              borderRadius: BorderRadius.circular(_tagRadius),
                            ),
                            child: Text(
                              interest,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Card-shaped placeholder: avatar, name, one line, tags.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: Dimens.gutter,
        vertical: Dimens.spaceM,
      ),
      child: Row(
        spacing: 14,
        children: [
          SkeletonBox(width: 72, height: 72, shape: BoxShape.circle),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Dimens.spaceTiny,
              children: [
                FractionallySizedBox(
                  widthFactor: 0.4,
                  child: SkeletonBox(height: 18),
                ),
                SkeletonBox(height: 12),
                FractionallySizedBox(
                  widthFactor: 0.7,
                  child: SkeletonBox(height: 18),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
