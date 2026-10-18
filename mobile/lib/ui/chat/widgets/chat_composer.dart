import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/ui/app_icon.dart';
import '../../core/ui/dashed_border.dart';
import '../view_model/chat_viewmodel.dart';
import 'photo_gallery_sheet.dart';
import 'attachment_previews.dart';

class ChatComposer extends StatefulWidget {
  const ChatComposer({
    super.key,
    required this.viewModel,
    required this.controller,
    required this.onSubmit,
  });

  final ChatViewModel viewModel;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_focusChanged);
  }

  void _focusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final viewModel = widget.viewModel;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (viewModel.isOffline)
          Semantics(
            liveRegion: true,
            child: Container(
              margin: const EdgeInsets.symmetric(
                horizontal: Dimens.spaceChat,
                vertical: Dimens.spaceS,
              ),
              padding: const EdgeInsets.all(Dimens.spaceM),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                border: Border.all(
                  color: colors.secondaryFixed,
                  width: Dimens.borderWidth,
                ),
                borderRadius: BorderRadius.circular(Dimens.spaceChat),
              ),
              child: Row(
                spacing: Dimens.spaceS,
                children: [
                  AppIcon(
                    AppIconName.wifiOff,
                    color: colors.error,
                    size: Dimens.iconS,
                  ),
                  Expanded(
                    child: Text(
                      'No internet. Trying again…',
                      style: TextStyle(
                        letterSpacing: 0,
                        color: colors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox.square(
                    dimension: Dimens.iconS,
                    child: CircularProgressIndicator(
                      strokeWidth: Dimens.borderWidth,
                      color: colors.error,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Padding(
            padding: Dimens.chatMemoryPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: Dimens.spaceTiny,
              children: [
                AppIcon(
                  AppIconName.lock,
                  color: colors.onSurfaceVariant,
                  size: Dimens.iconXs,
                ),
                Flexible(
                  child: Text(
                    'Memory is off. This moment can just be a moment.',
                    style: TextStyle(
                      letterSpacing: 0,
                      color: colors.onSurfaceVariant,
                      fontSize: 10,
                      height: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: Dimens.chatComposerPadding,
          child: CustomPaint(
            foregroundPainter: viewModel.isOffline
                ? DashedBorderPainter(
                    color: colors.outline,
                    radius: Dimens.radiusL,
                  )
                : null,
            child: Container(
              decoration: BoxDecoration(
                color: _focusNode.hasFocus
                    ? colors.surface
                    : colors.surfaceContainerLow,
                border: viewModel.isOffline
                    ? null
                    : Border.all(
                        color: _focusNode.hasFocus
                            ? colors.primaryFixed
                            : colors.outlineVariant,
                        width: Dimens.borderWidth,
                      ),
                borderRadius: BorderRadius.circular(Dimens.radiusL),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimens.borderWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (viewModel.draftImages.isNotEmpty)
                      AttachmentPreviews(viewModel: viewModel),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          style: IconButton.styleFrom(
                            minimumSize: const Size.square(Dimens.minTapTarget),
                            maximumSize: const Size.square(Dimens.minTapTarget),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          tooltip: 'Share a photo',
                          onPressed: viewModel.canCompose
                              ? () {
                                  FocusScope.of(context).unfocus();
                                  viewModel.openGallery();
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    useSafeArea: true,
                                    backgroundColor: colors.surface,
                                    builder: (_) =>
                                        PhotoGallerySheet(viewModel: viewModel),
                                  );
                                }
                              : null,
                          constraints: const BoxConstraints(
                            minWidth: Dimens.minTapTarget,
                            minHeight: Dimens.minTapTarget,
                          ),
                          icon: AppIcon(
                            AppIconName.image,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            focusNode: _focusNode,
                            readOnly: !viewModel.canCompose,
                            minLines: 1,
                            maxLines: 4,
                            maxLength: 1000,
                            keyboardType: TextInputType.multiline,
                            textCapitalization: TextCapitalization.sentences,
                            style: TextStyle(
                              letterSpacing: 0,
                              color: colors.onSurface,
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText: viewModel.isOffline
                                  ? 'Waiting for connection…'
                                  : viewModel.draftImages.isEmpty
                                  ? 'Share a thought…'
                                  : 'Add a message…',
                              hintStyle: TextStyle(
                                letterSpacing: 0,
                                color: colors.onSurfaceVariant,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              filled: false,
                              contentPadding: Dimens.chatInputPadding,
                              isDense: true,
                              constraints: const BoxConstraints(
                                minHeight: Dimens.minTapTarget,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                          ),
                        ),
                        Semantics(
                          liveRegion: viewModel.send.running,
                          child: IconButton(
                            tooltip: viewModel.send.running
                                ? 'Sending'
                                : 'Send message',
                            onPressed: viewModel.canSend
                                ? widget.onSubmit
                                : null,
                            style: IconButton.styleFrom(
                              minimumSize: const Size.square(
                                Dimens.minTapTarget,
                              ),
                              maximumSize: const Size.square(
                                Dimens.minTapTarget,
                              ),
                              padding: const EdgeInsets.all(Dimens.space2xs),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Container(
                              width: Dimens.sendVisual,
                              height: Dimens.sendVisual,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    viewModel.canSend || viewModel.send.running
                                    ? colors.primary
                                    : colors.outlineVariant,
                                shape: BoxShape.circle,
                              ),
                              child: viewModel.send.running
                                  ? SizedBox.square(
                                      dimension: Dimens.iconS,
                                      child: CircularProgressIndicator(
                                        strokeWidth: Dimens.borderWidth,
                                        color: colors.onPrimary,
                                      ),
                                    )
                                  : AppIcon(
                                      AppIconName.send,
                                      color: viewModel.canSend
                                          ? colors.onPrimary
                                          : colors.onSurfaceVariant,
                                      size: Dimens.iconS,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
