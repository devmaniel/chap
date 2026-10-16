import 'package:flutter/material.dart';

import '../themes/dimens.dart';

enum AppTab { chats, discover, people }

/// Bottom tab bar floating above the page as a rounded island.
class IslandNav extends StatelessWidget {
  const IslandNav({super.key, required this.current, required this.onSelect});

  static const _edge = 4.0;
  static const _tabMinHeight = 58.0;

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(Dimens.radiusL);

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(
        Dimens.spaceL,
        0,
        Dimens.spaceL,
        Dimens.spaceM,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: radius,
          border: Border.all(
            color: colors.outlineVariant,
            width: Dimens.borderWidth,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.outlineVariant,
              offset: const Offset(0, _edge),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimens.spaceXs),
          child: Row(
            children: [
              for (final (tab, label, icon) in const [
                (AppTab.chats, 'Chats', Icons.chat_bubble_outline_rounded),
                (AppTab.discover, 'Discover', Icons.explore_outlined),
                (AppTab.people, 'People', Icons.people_outline_rounded),
              ])
                Expanded(
                  child: _Tab(
                    label: label,
                    icon: icon,
                    isCurrent: tab == current,
                    onTap: () => onSelect(tab),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.isCurrent,
    required this.onTap,
  });

  static const _iconSize = 22.0;

  final String label;
  final IconData icon;
  final bool isCurrent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ink = isCurrent ? colors.onPrimaryContainer : colors.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: isCurrent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Dimens.radius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: IslandNav._tabMinHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: Dimens.spaceXs / 2,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.spaceL,
                  vertical: Dimens.spaceXs / 2,
                ),
                decoration: BoxDecoration(
                  color: isCurrent ? colors.primaryContainer : null,
                  borderRadius: BorderRadius.circular(Dimens.radiusS),
                  border: Border.all(
                    color: isCurrent ? colors.primaryFixed : Colors.transparent,
                    width: Dimens.borderWidth,
                  ),
                ),
                child: Icon(icon, color: ink, size: _iconSize),
              ),
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
