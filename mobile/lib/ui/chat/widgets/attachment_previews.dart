import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/ui/app_icon.dart';
import '../view_model/chat_viewmodel.dart';

const _pickSize = 56.0;
const _pickGap = Dimens.spaceSm;
const _dotSize = 22.0;
const _dotGlyph = 14.0;

/// The dot overhangs the photo corner by 3px, as in the mockup.
const _dotInset = _pickGap - 3;

class AttachmentPreviews extends StatelessWidget {
  const AttachmentPreviews({super.key, required this.viewModel});
  final ChatViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.only(left: _pickGap, bottom: Dimens.space2xs),
      child: Row(
        children: [
          for (final (index, path) in viewModel.draftImages.indexed)
            // Each pick reserves the gap above and after its photo, so the
            // x's full tap area stays inside its bounds and stays tappable.
            SizedBox.square(
              dimension: _pickSize + _pickGap,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Dimens.radiusS),
                      child: Image.file(
                        File(path),
                        width: _pickSize,
                        height: _pickSize,
                        fit: BoxFit.cover,
                        semanticLabel: 'Picked photo ${index + 1}',
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () => viewModel.removeImage(path),
                      tooltip: 'Remove photo ${index + 1}',
                      style: IconButton.styleFrom(
                        fixedSize: const Size.square(Dimens.minTapTarget),
                        padding: const EdgeInsets.only(
                          top: _dotInset,
                          right: _dotInset,
                        ),
                        alignment: Alignment.topRight,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: Container(
                        width: _dotSize,
                        height: _dotSize,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: colors.onSurface,
                          shape: BoxShape.circle,
                        ),
                        child: AppIcon(
                          AppIconName.close,
                          color: colors.surface,
                          size: _dotGlyph,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
