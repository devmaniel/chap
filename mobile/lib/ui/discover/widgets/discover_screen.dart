import 'dart:math' as math;

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
import '../../core/ui/raised_box.dart';
import '../../core/ui/skeleton.dart';
import '../view_model/discover_viewmodel.dart';

/// Character cards in a grid, narrowed by one interest at a time.
class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key, required this.viewModel});

  static const _skeletonCards = 4;

  final DiscoverViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel.changes,
      builder: (context, _) => Scaffold(
        bottomNavigationBar: BottomNav(
          current: AppTab.discover,
          onSelect: (tab) => switch (tab) {
            AppTab.chats => context.go(Routes.chats),
            AppTab.discover => null,
            AppTab.friends => context.go(Routes.friends),
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
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.gutter,
            14,
            Dimens.gutter,
            Dimens.spaceTiny,
          ),
          child: Row(
            spacing: Dimens.spaceM,
            children: [
              Expanded(
                child: Text(
                  'Discover',
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
              AppIcon(AppIconName.spark, color: colors.onSurface),
            ],
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
            'A new conversation starts with a little curiosity.',
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.6,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(
            Dimens.gutter,
            0,
            Dimens.gutter,
            Dimens.spaceXl,
          ),
          child: Row(
            spacing: Dimens.spaceS,
            children: [
              for (final filter in DiscoverViewModel.filters)
                _FilterChip(
                  label: filter,
                  isSelected: filter == viewModel.filter,
                  onTap: () => viewModel.selectFilter(filter),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Dimens.gutter,
            0,
            Dimens.gutter,
            Dimens.gutter,
          ),
          child: _buildGrid(context),
        ),
      ],
    );
  }

  /// Skeleton cards while loading, Retry on failure, then the characters.
  Widget _buildGrid(BuildContext context) {
    if (viewModel.load.running) {
      return Semantics(
        liveRegion: true,
        label: 'Loading characters',
        excludeSemantics: true,
        child: _CharacterGrid(
          itemCount: _skeletonCards,
          itemBuilder: (_) => const _SkeletonCard(),
        ),
      );
    }
    if (viewModel.load.error) {
      return LoadError(
        message: 'Couldn’t load characters.',
        onRetry: viewModel.load.execute,
      );
    }
    final characters = viewModel.characters;
    return _CharacterGrid(
      itemCount: characters.length,
      itemBuilder: (i) => _CharacterCard(
        character: characters[i],
        onTap: () => context.push<void>(Routes.character(characters[i].id)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  static const _radius = 14.0;

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      toggled: isSelected,
      child: RaisedBox(
        onTap: onTap,
        radius: _radius,
        color: isSelected ? colors.primaryContainer : colors.surface,
        borderColor: isSelected ? colors.primaryFixed : null,
        constraints: const BoxConstraints(minHeight: Dimens.minTapTarget),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              color: isSelected ? colors.onPrimaryContainer : colors.onSurface,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

/// As many 136-wide columns as fit, sharing the width.
class _CharacterGrid extends StatelessWidget {
  const _CharacterGrid({required this.itemCount, required this.itemBuilder});

  static const _minCardWidth = 136.0;
  static const _gap = 14.0;

  final int itemCount;
  final Widget Function(int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = math.max(
          1,
          ((constraints.maxWidth + _gap) / (_minCardWidth + _gap)).floor(),
        );
        return Column(
          spacing: _gap,
          children: [
            for (var start = 0; start < itemCount; start += columns)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: _gap,
                children: [
                  for (var i = start; i < start + columns; i++)
                    Expanded(
                      child: i < itemCount
                          ? itemBuilder(i)
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _CharacterCard extends StatelessWidget {
  const _CharacterCard({required this.character, required this.onTap});

  static const _radius = 20.0;
  static const _artMaxSize = 130.0;
  static const _artWidthFactor = 0.82;
  static const _artSink = 8.0;
  static const _descriptionSize = 12.0;

  final Character character;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);

    return Semantics(
      label: 'Meet ${character.name}, AI character',
      excludeSemantics: true,
      child: RaisedBox(
        onTap: onTap,
        radius: _radius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 5 / 4,
              child: ColoredBox(
                color: Illustrations.tone(character.id),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = math.min(
                      (constraints.maxWidth - 2 * Dimens.spaceS) *
                          _artWidthFactor,
                      _artMaxSize,
                    );
                    return Stack(
                      children: [
                        Positioned(
                          left: (constraints.maxWidth - size) / 2,
                          bottom: -_artSink,
                          width: size,
                          height: size,
                          child: Image.asset(
                            character.portraitAsset,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Dimens.spaceM,
                Dimens.spaceSm,
                Dimens.spaceM,
                Dimens.spaceM,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    spacing: Dimens.spaceXs,
                    children: [
                      Expanded(
                        child: Text(
                          character.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const AiTag(),
                    ],
                  ),
                  const SizedBox(height: Dimens.space2xs),
                  ConstrainedBox(
                    // Two lines tall even when the line is short.
                    constraints: BoxConstraints(
                      minHeight: textScaler.scale(_descriptionSize * 3.1),
                    ),
                    child: Text(
                      character.tagline,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: _descriptionSize,
                        fontWeight: FontWeight.w600,
                        height: 1.55,
                      ),
                    ),
                  ),
                  const SizedBox(height: Dimens.spaceSm),
                  Text(
                    character.interests.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.onPrimaryContainer,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Card-shaped placeholder: art block, name, two lines, interests.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  static const _radius = 20.0;

  @override
  Widget build(BuildContext context) {
    return RaisedBox(
      radius: _radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AspectRatio(aspectRatio: 5 / 4, child: SkeletonBox(radius: 0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimens.spaceM,
              Dimens.spaceSm,
              Dimens.spaceM,
              Dimens.spaceM,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: Dimens.spaceXs,
              children: const [
                FractionallySizedBox(
                  widthFactor: 0.55,
                  child: SkeletonBox(height: 16),
                ),
                SkeletonBox(height: 12),
                FractionallySizedBox(
                  widthFactor: 0.7,
                  child: SkeletonBox(height: 12),
                ),
                SizedBox(height: Dimens.space2xs),
                FractionallySizedBox(
                  widthFactor: 0.8,
                  child: SkeletonBox(height: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
