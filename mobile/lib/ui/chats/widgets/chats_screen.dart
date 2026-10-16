import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/ui/app_icon.dart';
import '../../core/ui/bottom_nav.dart';
import '../view_model/chats_viewmodel.dart';
import 'chat_search_bar.dart';
import 'chat_tile.dart';

/// Inbox: one list, newest first. Search lives behind the heading icon.
class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key, required this.viewModel});

  final ChatsViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([viewModel, viewModel.load]),
      builder: (context, _) => Scaffold(
        bottomNavigationBar: BottomNav(current: AppTab.chats, onSelect: (_) {}),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _AppHeader(),
              if (viewModel.isSearching)
                ChatSearchBar(viewModel: viewModel)
              else
                _Heading(onSearch: viewModel.openSearch),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (viewModel.load.running) {
      return Center(
        child: Semantics(
          liveRegion: true,
          label: 'Loading chats',
          child: const CircularProgressIndicator(),
        ),
      );
    }

    final chats = viewModel.chats;
    final isSearching = viewModel.isSearching;
    final query = viewModel.query.trim();
    if (isSearching && query.isNotEmpty && chats.isEmpty) {
      return _NoMatches(query: query);
    }

    final now = DateTime.now();
    return ListView(
      children: [
        if (isSearching)
          _ListLabel(
            query.isEmpty
                ? 'ALL CHATS'
                : '${chats.length} ${chats.length == 1 ? 'CHAT' : 'CHATS'}',
          ),
        for (final (index, chat) in chats.indexed)
          ChatTile(
            chat: chat,
            now: now,
            query: isSearching ? query : '',
            showDivider: index > 0,
            onTap: () {},
          ),
        if (!isSearching) ...[
          MeetTile(showDivider: chats.isNotEmpty, onTap: () {}),
          const _QuietNote(),
        ],
      ],
    );
  }
}

/// Wordmark on the left, your initials on the right.
class _AppHeader extends StatelessWidget {
  const _AppHeader();

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

class _Heading extends StatelessWidget {
  const _Heading({required this.onSearch});

  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.gutter,
        10,
        Dimens.gutter,
        Dimens.spaceL,
      ),
      child: Row(
        spacing: Dimens.spaceM,
        children: [
          Expanded(
            child: Text(
              'Chats',
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
          IconButton(
            onPressed: onSearch,
            tooltip: 'Search chats',
            style: IconButton.styleFrom(
              backgroundColor: colors.surfaceContainerLow,
              fixedSize: const Size.square(Dimens.minTapTarget),
              padding: EdgeInsets.zero,
            ),
            icon: AppIcon(AppIconName.search, color: colors.onSurface),
          ),
        ],
      ),
    );
  }
}

class _ListLabel extends StatelessWidget {
  const _ListLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Dimens.gutter, 0, Dimens.gutter, 2),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.96,
        ),
      ),
    );
  }
}

/// Spark and one line under the list.
class _QuietNote extends StatelessWidget {
  const _QuietNote();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.gutter,
        Dimens.gutter,
        Dimens.gutter,
        Dimens.spaceL,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: Dimens.spaceXs,
        children: [
          AppIcon(
            AppIconName.spark,
            size: 14,
            color: colors.onTertiaryContainer,
          ),
          Flexible(
            child: Text(
              'Fictional friends. Room to be yourself.',
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nothing matches: their words shown back, then a hint.
class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.query});

  static const _iconTile = 72.0;
  static const _textMaxWidth = 270.0;

  final String query;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bodyStyle = TextStyle(
      color: colors.onSurfaceVariant,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.55,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 28),
      children: [
        Semantics(
          liveRegion: true,
          child: Column(
            spacing: Dimens.spaceXs,
            children: [
              Container(
                width: _iconTile,
                height: _iconTile,
                margin: const EdgeInsets.only(bottom: Dimens.spaceM),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(Dimens.radiusL),
                  boxShadow: [
                    BoxShadow(
                      color: colors.outlineVariant,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AppIcon(
                  AppIconName.search,
                  size: 32,
                  color: colors.onSurfaceVariant,
                ),
              ),
              Text(
                'No matches',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _textMaxWidth),
                child: Column(
                  children: [
                    Text(
                      'Nothing for “$query”.',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: bodyStyle.copyWith(color: colors.onSurface),
                    ),
                    Text(
                      'Try a name or a word from the chat.',
                      textAlign: TextAlign.center,
                      style: bodyStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
