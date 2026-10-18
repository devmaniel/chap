import 'package:flutter/material.dart';

import '../../core/themes/dimens.dart';
import 'photo_gallery_header.dart';
import '../view_model/chat_viewmodel.dart';

class PhotoGallerySheet extends StatefulWidget {
  const PhotoGallerySheet({super.key, required this.viewModel});

  final ChatViewModel viewModel;

  @override
  State<PhotoGallerySheet> createState() => _PhotoGallerySheetState();
}

class _PhotoGallerySheetState extends State<PhotoGallerySheet> {
  final _sheetController = DraggableScrollableController();
  late final _lifecycle = AppLifecycleListener(
    onResume: () {
      if (widget.viewModel.loadPhotos.error) {
        widget.viewModel.loadPhotos.execute();
      }
    },
  );

  @override
  void initState() {
    super.initState();
    _lifecycle;
    _sheetController.addListener(_extentChanged);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _extentChanged() => setState(() {});

  Future<void> _add() async {
    await widget.viewModel.attachImages.execute();
    if (mounted && widget.viewModel.attachImages.completed) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final colors = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: .62,
      minChildSize: .4,
      maxChildSize: 1,
      expand: false,
      builder: (context, scrollController) => ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) => SafeArea(
          top: false,
          child: Column(
            children: [
              PhotoGalleryHeader(
                viewModel: viewModel,
                controller: _sheetController,
                onAdd: _add,
              ),
              if (viewModel.attachImages.error)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    'Try adding photos again.',
                    style: TextStyle(letterSpacing: 0, color: colors.error),
                  ),
                ),
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.extentAfter <
                            Dimens.minTapTarget * 4 &&
                        viewModel.hasMorePhotos &&
                        !viewModel.loadPhotos.error) {
                      viewModel.loadPhotos.execute();
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    controller: scrollController,
                    slivers: [
                      SliverGrid.builder(
                        itemCount: viewModel.photos.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: Dimens.borderWidth,
                              crossAxisSpacing: Dimens.borderWidth,
                            ),
                        itemBuilder: (context, index) {
                          final photo = viewModel.photos[index];
                          final selection = viewModel.selectedPhotos.indexOf(
                            photo.id,
                          );
                          return Semantics(
                            button: true,
                            selected: selection >= 0,
                            label:
                                'Photo ${index + 1}${selection >= 0 ? ', selected ${selection + 1}' : ''}',
                            excludeSemantics: true,
                            child: InkWell(
                              onTap: () => viewModel.togglePhoto(photo.id),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.memory(
                                    photo.thumbnail,
                                    fit: BoxFit.cover,
                                    excludeFromSemantics: true,
                                    gaplessPlayback: true,
                                  ),
                                  if (selection >= 0)
                                    DecoratedBox(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: colors.primary,
                                          width: Dimens.borderWidth,
                                        ),
                                      ),
                                      child: Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          margin: const EdgeInsets.all(
                                            Dimens.spaceXs,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: Dimens.space2xs,
                                            vertical: Dimens.borderWidth,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${selection + 1}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              letterSpacing: 0,
                                              color: colors.onPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(Dimens.spaceXl),
                          child: Column(
                            children: [
                              if (viewModel.loadPhotos.running)
                                Semantics(
                                  liveRegion: true,
                                  label: 'Loading photos',
                                  child: CircularProgressIndicator(
                                    color: colors.primary,
                                  ),
                                )
                              else if (viewModel.loadPhotos.error) ...[
                                Text(
                                  viewModel.photoAccessDenied
                                      ? 'Allow photos in Settings.'
                                      : 'Can’t load photos.',
                                ),
                                if (viewModel.photoAccessDenied)
                                  TextButton(
                                    onPressed: viewModel.photoSettings.running
                                        ? null
                                        : viewModel.photoSettings.execute,
                                    child: const Text('Open settings'),
                                  ),
                                TextButton(
                                  onPressed: viewModel.loadPhotos.execute,
                                  child: const Text('Retry'),
                                ),
                              ] else if (viewModel.photos.isEmpty)
                                const Text('No photos yet.')
                              else if (viewModel.hasMorePhotos)
                                TextButton(
                                  onPressed: viewModel.loadPhotos.execute,
                                  child: const Text('Load more'),
                                ),
                            ],
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
      ),
    );
  }
}
