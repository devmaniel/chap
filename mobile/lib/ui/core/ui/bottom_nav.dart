import 'package:flutter/material.dart';

import '../themes/dimens.dart';
import 'app_icon.dart';

enum AppTab { chats, discover, friends }

/// App tab bar pinned to the bottom, under a hairline.
class BottomNav extends StatelessWidget {
  const BottomNav({super.key, required this.current, required this.onSelect});

  final AppTab current;
  final ValueChanged<AppTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant,
            width: Dimens.borderWidth,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, Dimens.spaceS, 14, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (tab, label, icon) in const [
                (AppTab.chats, 'Chats', AppIconName.chat),
                (AppTab.discover, 'Discover', AppIconName.compass),
                (AppTab.friends, 'Friends', AppIconName.friends),
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

  static const _minHeight = 58.0;
  static const _pillRadius = 14.0;

  final String label;
  final AppIconName icon;
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
        borderRadius: BorderRadius.circular(_pillRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimens.spaceL,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isCurrent ? colors.primaryContainer : null,
                    borderRadius: BorderRadius.circular(_pillRadius),
                    border: Border.all(
                      color: isCurrent
                          ? colors.primaryFixed
                          : Colors.transparent,
                      width: Dimens.borderWidth,
                    ),
                  ),
                  child: AppIcon(icon, color: ink),
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
      ),
    );
  }
}
