import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/ui/island_nav.dart';
import '../view_model/chats_viewmodel.dart';
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
        extendBody: true,
        bottomNavigationBar: IslandNav(current: AppTab.chats, onSelect: (_) {}),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (viewModel.isSearching)
                _SearchBar(viewModel: viewModel)
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
        if (!isSearching) MeetTile(showDivider: chats.isNotEmpty, onTap: () {}),
      ],
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
              foregroundColor: colors.onSurface,
              fixedSize: const Size.square(Dimens.minTapTarget),
            ),
            icon: const Icon(Icons.search_rounded),
          ),
        ],
      ),
    );
  }
}

/// Replaces the heading while searching. Focused on open; Cancel closes it.
class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.viewModel});

  final ChatsViewModel viewModel;

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  static const _fieldMinHeight = 48.0;
  static const _focusRing = 4.0;
  static const _clearSize = 20.0;

  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.viewModel.setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final viewModel = widget.viewModel;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Dimens.gutter,
        10,
        Dimens.spaceM,
        Dimens.spaceL,
      ),
      child: Row(
        spacing: Dimens.spaceXs,
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: _fieldMinHeight),
              padding: const EdgeInsets.only(left: 14, right: 2),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(Dimens.radius),
                border: Border.all(
                  color: colors.primary,
                  width: Dimens.borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primaryContainer,
                    spreadRadius: _focusRing,
                  ),
                ],
              ),
              child: Row(
                spacing: Dimens.spaceS,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: colors.onPrimaryContainer,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      onChanged: viewModel.setQuery,
                      textInputAction: TextInputAction.search,
                      cursorColor: colors.primary,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Name or message',
                        filled: false,
                        isDense: true,
                        constraints: BoxConstraints(),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: Dimens.spaceM,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                    ),
                  ),
                  if (viewModel.query.isNotEmpty)
                    IconButton(
                      onPressed: _clear,
                      tooltip: 'Clear search',
                      constraints: const BoxConstraints.tightFor(
                        width: Dimens.minTapTarget,
                        height: Dimens.minTapTarget,
                      ),
                      icon: Container(
                        width: _clearSize,
                        height: _clearSize,
                        decoration: BoxDecoration(
                          color: colors.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 14,
                          color: colors.surface,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: viewModel.closeSearch,
            style: TextButton.styleFrom(
              textStyle: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            child: const Text('Cancel'),
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

/// Nothing matches: their words shown back, then a hint.
class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.query});

  static const _iconTile = 72.0;

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
            children: [
              Container(
                width: _iconTile,
                height: _iconTile,
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
                child: Icon(
                  Icons.search_rounded,
                  size: 32,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'No matches',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: Dimens.spaceXs),
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
    );
  }
}
