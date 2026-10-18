import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../domain/models/message/message.dart';
import '../../core/themes/dimens.dart';
import '../view_model/chat_viewmodel.dart';
import 'chat_animations.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.portraitAsset,
    this.pendingStatus,
    this.onRetry,
    this.animateReply = false,
    this.onRevealComplete,
  });

  final Message message;
  final String portraitAsset;
  final PendingStatus? pendingStatus;
  final VoidCallback? onRetry;
  final bool animateReply;
  final VoidCallback? onRevealComplete;

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
                    TweenAnimationBuilder<double>(
                      key: ValueKey(pendingStatus),
                      tween: Tween(begin: failed ? 1 : 0, end: 0),
                      duration:
                          !failed || MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 400),
                      builder: (context, value, child) => Transform.translate(
                        offset: Offset(
                          math.sin(value * math.pi * 5) * Dimens.spaceXs,
                          0,
                        ),
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
                            width: message.imagePaths.isEmpty
                                ? Dimens.borderWidth
                                : 0,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(Dimens.bubbleRadius),
                            topRight: const Radius.circular(
                              Dimens.bubbleRadius,
                            ),
                            bottomLeft: Radius.circular(
                              message.isFromYou
                                  ? Dimens.bubbleRadius
                                  : Dimens.spaceXs,
                            ),
                            bottomRight: Radius.circular(
                              message.isFromYou
                                  ? Dimens.spaceXs
                                  : Dimens.bubbleRadius,
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
                            if (message.text.isNotEmpty)
                              if (animateReply)
                                ReplyText(
                                  text: message.text,
                                  style: style,
                                  onComplete: onRevealComplete!,
                                )
                              else
                                Text(message.text, style: style),
                          ],
                        ),
                      ),
                    ),
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
