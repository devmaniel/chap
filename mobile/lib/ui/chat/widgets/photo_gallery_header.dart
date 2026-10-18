import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import '../../core/ui/app_icon.dart';
import '../view_model/chat_viewmodel.dart';

class PhotoGalleryHeader extends StatelessWidget {
  const PhotoGalleryHeader({
    super.key,
    required this.viewModel,
    required this.controller,
    required this.onAdd,
  });
  final ChatViewModel viewModel;
  final DraggableScrollableController controller;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      key: const ValueKey('photo-sheet-handle'),
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        final height = MediaQuery.sizeOf(context).height;
        controller.jumpTo(
          (controller.size - details.delta.dy / height).clamp(.4, 1),
        );
      },
      child: Column(
        children: [
          if (!controller.isAttached || controller.size < .99)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Dimens.spaceM),
              child: Container(
                width: Dimens.galleryHandle,
                height: Dimens.spaceTiny,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(Dimens.spaceTiny),
                ),
              ),
            )
          else
            const SizedBox(height: Dimens.spaceS),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Dimens.spaceS,
              0,
              Dimens.spaceS,
              Dimens.spaceXs,
            ),
            child: Row(
              children: [
                SizedBox(
                  width:
                      Dimens.gallerySide *
                      MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.5),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close photos',
                      style: IconButton.styleFrom(
                        minimumSize: const Size.square(Dimens.minTapTarget),
                        maximumSize: const Size.square(Dimens.minTapTarget),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: AppIcon(AppIconName.close, color: colors.onSurface),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Recents',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      letterSpacing: 0,
                      color: colors.onSurface,
                      fontSize: 16,
                      height: 1.4,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(
                  width:
                      Dimens.gallerySide *
                      MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.5),
                  child: viewModel.attachImages.running
                      ? Semantics(
                          liveRegion: true,
                          label: 'Adding photos',
                          child: Center(
                            child: SizedBox.square(
                              dimension: Dimens.spinner,
                              child: CircularProgressIndicator(
                                strokeWidth: Dimens.borderWidth,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                          ),
                        )
                      : TextButton(
                          onPressed: viewModel.selectedPhotos.isEmpty
                              ? null
                              : onAdd,
                          style: TextButton.styleFrom(
                            foregroundColor: colors.primary,
                            minimumSize: const Size.square(Dimens.minTapTarget),
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimens.spaceM,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(
                              fontFamily: 'Nunito',
                              fontSize: 15,
                              height: 1.4,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                          ),
                          child: Text(
                            viewModel.selectedPhotos.isEmpty
                                ? 'Add'
                                : 'Add ${viewModel.selectedPhotos.length}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
