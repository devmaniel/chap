import 'package:flutter/material.dart';

import '../../../domain/models/chat/chat.dart';
import '../../core/themes/dimens.dart';
import '../../core/ui/app_icon.dart';

class ChatHeader extends StatelessWidget {
  const ChatHeader({super.key, required this.chat});

  final Chat? chat;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final buttonStyle = IconButton.styleFrom(
      minimumSize: const Size.square(Dimens.minTapTarget),
      maximumSize: const Size.square(Dimens.minTapTarget),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.zero,
    );
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant,
            width: Dimens.borderWidth,
          ),
        ),
      ),
      child: Padding(
        padding: Dimens.chatHeaderPadding,
        child: Row(
          spacing: Dimens.spaceS,
          children: [
            IconButton(
              tooltip: 'Back to chats',
              style: buttonStyle,
              onPressed: () => Navigator.of(context).pop(),
              icon: AppIcon(AppIconName.back, color: colors.onSurface),
            ),
            Expanded(
              child: chat == null
                  ? const SizedBox.shrink()
                  : Row(
                      spacing: Dimens.spaceSm,
                      children: [
                        ClipOval(
                          child: Image.asset(
                            chat!.portraitAsset,
                            width: Dimens.chatAvatar,
                            height: Dimens.chatAvatar,
                            fit: BoxFit.cover,
                            excludeFromSemantics: true,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chat!.friendName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  letterSpacing: 0,
                                  color: colors.onSurface,
                                  fontSize: 16,
                                  height: 1.4,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: Dimens.messageTimeInset),
                              Text(
                                'AI friend · ${chat!.friendVoice}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  letterSpacing: 0,
                                  color: colors.onSurfaceVariant,
                                  fontSize: 11,
                                  height: 1.4,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
            if (chat != null)
              IconButton(
                tooltip: 'Call ${chat!.friendName}',
                style: buttonStyle,
                onPressed: null,
                icon: AppIcon(AppIconName.phone, color: colors.onSurface),
              ),
          ],
        ),
      ),
    );
  }
}
