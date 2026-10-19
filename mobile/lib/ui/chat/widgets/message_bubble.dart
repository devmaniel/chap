import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/message/message.dart';
import '../../../domain/models/post/post.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/app_icon.dart';
import '../../core/ui/raised_box.dart';
import '../view_model/chat_viewmodel.dart';
import 'chat_animations.dart';
import 'post_ref_card.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.portraitAsset,
    required this.friendName,
    this.post,
    this.pendingStatus,
    this.onRetry,
    this.animateReply = false,
    this.onRevealComplete,
    this.onCallAgain,
  });

  final Message message;
  final String portraitAsset;
  final String friendName;

  /// The friend's post this message replies to.
  final Post? post;
  final PendingStatus? pendingStatus;
  final VoidCallback? onRetry;
  final bool animateReply;
  final VoidCallback? onRevealComplete;
  final VoidCallback? onCallAgain;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final failed = pendingStatus == PendingStatus.failed;
    final pending = pendingStatus != null;
    final ink = failed || !message.isFromYou
        ? colors.onSurface
        : pending
        ? colors.onPrimaryContainer
        : colors.onPrimary;
    final fill = message.isFromYou && !failed
        ? pending
              ? colors.primaryContainer
              : colors.primary
        : colors.surface;
    final line = failed
        ? colors.secondaryFixed
        : pending
        ? colors.primaryFixed
        : message.isFromYou
        ? colors.primary
        : colors.outlineVariant;
    final style = TextStyle(
      letterSpacing: 0,
      color: ink,
      fontSize: 14,
      height: 1.6,
      fontWeight: FontWeight.w600,
    );
    final bubble = message.callDuration != null
        ? _CallRecord(
            duration: message.callDuration!,
            friendName: friendName,
            onCallAgain: onCallAgain,
          )
        : TweenAnimationBuilder<double>(
            key: ValueKey(pendingStatus),
            tween: Tween(begin: failed ? 1 : 0, end: 0),
            duration: !failed || MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 400),
            builder: (context, value, child) => Transform.translate(
              offset: Offset(math.sin(value * math.pi * 5) * Dimens.spaceXs, 0),
              child: child,
            ),
            child: Container(
              padding: message.imagePaths.isEmpty
                  ? Dimens.chatBubblePadding
                  : const EdgeInsets.all(Dimens.spaceXs),
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(
                  color: line,
                  width: message.imagePaths.isEmpty ? Dimens.borderWidth : 0,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(Dimens.bubbleRadius),
                  topRight: const Radius.circular(Dimens.bubbleRadius),
                  bottomLeft: Radius.circular(
                    message.isFromYou ? Dimens.bubbleRadius : Dimens.spaceXs,
                  ),
                  bottomRight: Radius.circular(
                    message.isFromYou ? Dimens.spaceXs : Dimens.bubbleRadius,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: message.isFromYou && !pending && !failed
                        ? colors.primaryFixedDim
                        : line,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: Dimens.spaceS,
                children: [
                  if (post case final post?)
                    PostRefCard(
                      post: post,
                      friendName: friendName,
                      portraitAsset: portraitAsset,
                    ),
                  if (message.imagePaths.isNotEmpty)
                    LayoutBuilder(
                      builder: (context, imageConstraints) => Wrap(
                        spacing: Dimens.space2xs,
                        runSpacing: Dimens.space2xs,
                        children: [
                          for (final (index, path)
                              in message.imagePaths.indexed)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                Dimens.photoRadius,
                              ),
                              child: Image.file(
                                File(path),
                                width: message.imagePaths.length == 1
                                    ? imageConstraints.maxWidth
                                    : (imageConstraints.maxWidth -
                                              Dimens.space2xs) /
                                          2,
                                height: message.imagePaths.length == 1
                                    ? imageConstraints.maxWidth
                                    : (imageConstraints.maxWidth -
                                              Dimens.space2xs) /
                                          2,
                                fit: BoxFit.cover,
                                semanticLabel: 'Photo ${index + 1}',
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (message.text.isNotEmpty) Text(message.text, style: style),
                ],
              ),
            ),
          );
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimens.spaceChat),
      child: LayoutBuilder(
        builder: (context, constraints) => Row(
          mainAxisAlignment: message.isFromYou
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: Dimens.spaceS,
          children: [
            if (!message.isFromYou)
              ClipOval(
                child: Image.asset(
                  portraitAsset,
                  width: Dimens.messageAvatar,
                  height: Dimens.messageAvatar,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
              ),
            if (failed)
              Padding(
                padding: const EdgeInsets.only(bottom: Dimens.minTapTarget),
                child: Icon(
                  Icons.error,
                  color: colors.error,
                  size: Dimens.spinner,
                ),
              ),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: message.imagePaths.isEmpty
                      ? constraints.maxWidth * .82
                      : math.min(
                          constraints.maxWidth * .82,
                          Dimens.photoTile * 2 +
                              Dimens.space2xs +
                              Dimens.spaceXs * 2,
                        ),
                ),
                child: Column(
                  crossAxisAlignment: message.isFromYou
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (animateReply)
                      BubblePop(onComplete: onRevealComplete, child: bubble)
                    else
                      bubble,
                    Padding(
                      padding: const EdgeInsets.only(
                        top: Dimens.messageTimeGap,
                        left: Dimens.messageTimeInset,
                        right: Dimens.messageTimeInset,
                      ),
                      child: pendingStatus != null
                          ? _MessageStatus(
                              status: pendingStatus!,
                              onRetry: onRetry,
                            )
                          : Text(
                              '${message.isFromYou ? 'You · ' : ''}${messageTimeLabel(message.sentAt)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                letterSpacing: 0,
                                color: colors.onSurfaceVariant,
                                fontSize: 9,
                                height: 1.4,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageStatus extends StatelessWidget {
  const _MessageStatus({required this.status, this.onRetry});

  final PendingStatus status;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final failed = status == PendingStatus.failed;
    return Semantics(
      liveRegion: true,
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: Dimens.spaceXs,
        children: [
          if (status == PendingStatus.sending)
            SizedBox.square(
              dimension: Dimens.spaceM,
              child: CircularProgressIndicator(
                strokeWidth: Dimens.borderWidth,
                color: colors.onSurfaceVariant,
              ),
            ),
          Text(
            switch (status) {
              PendingStatus.sending => 'Sending…',
              PendingStatus.waitingForConnection => 'Waiting for connection…',
              PendingStatus.failed => 'Something went wrong.',
            },
            style: TextStyle(
              letterSpacing: 0,
              color: failed ? colors.error : colors.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (failed)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: colors.error),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}

/// A finished voice call in the thread: its length and Call again.
class _CallRecord extends StatelessWidget {
  const _CallRecord({
    required this.duration,
    required this.friendName,
    required this.onCallAgain,
  });

  final Duration duration;
  final String friendName;
  final VoidCallback? onCallAgain;

  static const _width = 220.0;
  static const _iconCircle = 36.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: _width,
      padding: const EdgeInsets.all(Dimens.spaceM),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: colors.outlineVariant,
          width: Dimens.borderWidth,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimens.bubbleRadius),
          topRight: Radius.circular(Dimens.bubbleRadius),
          bottomLeft: Radius.circular(Dimens.bubbleRadius),
          bottomRight: Radius.circular(Dimens.spaceXs),
        ),
        boxShadow: [
          BoxShadow(color: colors.outlineVariant, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Dimens.spaceM,
        children: [
          Row(
            spacing: Dimens.spaceSm,
            children: [
              Container(
                width: _iconCircle,
                height: _iconCircle,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryContainer,
                ),
                child: Center(
                  child: AppIcon(
                    AppIconName.phone,
                    color: colors.onPrimaryContainer,
                    size: Dimens.iconS,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Voice call',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        letterSpacing: 0,
                        color: colors.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      callDurationLabel(duration),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        letterSpacing: 0,
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Semantics(
            button: true,
            label: 'Call $friendName again',
            excludeSemantics: true,
            child: RaisedBox(
              onTap: onCallAgain,
              radius: Dimens.radiusS,
              constraints: const BoxConstraints(minHeight: Dimens.minTapTarget),
              child: Center(
                child: Text(
                  'Call again',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    letterSpacing: 0,
                    color: colors.onPrimaryContainer,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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
