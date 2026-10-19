import 'package:flutter/material.dart';

import '../../../data/repositories/chat/chat_repository.dart';
import '../../../domain/models/chat/chat.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/ai_tag.dart';
import '../../core/ui/app_icon.dart';
import '../../core/ui/dashed_border.dart';
import '../view_model/chats_viewmodel.dart';

const _avatarSize = 52.0;
const _avatarGap = 14.0;

/// One inbox row. Unread: dark bold preview, blue time, count badge.
/// Read: grey. A [draft] replaces the preview and the badge.
/// The part matching [query] is highlighted.
class ChatTile extends StatelessWidget {
  const ChatTile({
    super.key,
    required this.chat,
    required this.now,
    this.draft,
    required this.onTap,
    this.query = '',
    this.showDivider = true,
  });

  final Chat chat;
  final Draft? draft;
  final DateTime now;
  final VoidCallback onTap;
  final String query;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isUnread = chat.isUnread;
    final markStyle = TextStyle(
      backgroundColor: colors.tertiaryContainer,
      color: colors.onSurface,
    );

    return _TileFrame(
      onTap: onTap,
      showDivider: showDivider,
      leading: ClipOval(
        child: Image.asset(
          chat.portraitAsset,
          width: _avatarSize,
          height: _avatarSize,
          fit: BoxFit.cover,
          excludeFromSemantics: true,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Row(
            children: [
              // Name and tag get two thirds; the time shrinks first at large text.
              Expanded(
                flex: 2,
                child: Row(
                  spacing: Dimens.spaceXs,
                  children: [
                    Flexible(
                      child: Text.rich(
                        _highlight(chat.friendName, query, markStyle),
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
              ),
              const SizedBox(width: Dimens.spaceS),
              Expanded(
                child: Text(
                  chatTimeLabel(chat.lastMessageAt, now),
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnread
                        ? colors.onPrimaryContainer
                        : colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: Text.rich(
                  draft == null
                      ? _highlight(chat.lastMessage, query, markStyle)
                      : TextSpan(
                          children: [
                            TextSpan(
                              text: 'Draft: ',
                              style: TextStyle(
                                color: colors.error,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            TextSpan(text: draftPreview(draft!)),
                          ],
                        ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isUnread
                        ? colors.onSurface
                        : colors.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ),
              if (isUnread && draft == null)
                _UnreadBadge(count: chat.unreadCount),
            ],
          ),
        ],
      ),
    );
  }
}

/// Last row of the inbox, leading to Discover.
class MeetTile extends StatelessWidget {
  const MeetTile({super.key, required this.onTap, this.showDivider = true});

  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return _TileFrame(
      onTap: onTap,
      showDivider: showDivider,
      leading: CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: colors.primaryFixed,
          radius: _avatarSize / 2,
        ),
        child: Container(
          width: _avatarSize,
          height: _avatarSize,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: AppIcon(AppIconName.plus, color: colors.onPrimaryContainer),
        ),
      ),
      body: Row(
        spacing: Dimens.spaceM,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(
                  'Meet someone new',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onPrimaryContainer,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Find a personality you click with.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          AppIcon(AppIconName.arrow, size: 20, color: colors.onSurfaceVariant),
        ],
      ),
    );
  }
}

/// Tappable row with the divider starting at the text, not the screen edge.
class _TileFrame extends StatelessWidget {
  const _TileFrame({
    required this.onTap,
    required this.showDivider,
    required this.leading,
    required this.body,
  });

  final VoidCallback onTap;
  final bool showDivider;
  final Widget leading;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return MergeSemantics(
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimens.gutter),
            child: Row(
              spacing: _avatarGap,
              children: [
                leading,
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: showDivider
                              ? colors.outlineVariant
                              : Colors.transparent,
                          width: Dimens.borderWidth,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: _avatarGap),
                      child: body,
                    ),
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

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  static const _size = 22.0;

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      label: '$count unread',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: _size, minHeight: _size),
        padding: const EdgeInsets.symmetric(horizontal: 7),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.onPrimaryContainer,
          borderRadius: BorderRadius.circular(_size / 2),
        ),
        child: Text(
          '$count',
          style: TextStyle(
            color: colors.onPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// [text] with the first case-insensitive match of [query] in [markStyle].
TextSpan _highlight(String text, String query, TextStyle markStyle) {
  final needle = query.trim().toLowerCase();
  final start = needle.isEmpty ? -1 : text.toLowerCase().indexOf(needle);
  if (start < 0) return TextSpan(text: text);
  final end = start + needle.length;
  return TextSpan(
    children: [
      TextSpan(text: text.substring(0, start)),
      TextSpan(text: text.substring(start, end), style: markStyle),
      TextSpan(text: text.substring(end)),
    ],
  );
}
