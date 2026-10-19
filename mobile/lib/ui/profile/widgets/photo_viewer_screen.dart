import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../routing/routes.dart';
import '../../core/themes/dimens.dart';
import '../../core/themes/illustrations.dart';
import '../../core/ui/app_icon.dart';
import '../view_model/photo_viewer_viewmodel.dart';
import '../view_model/profile_viewmodel.dart';
import 'post_card.dart';

/// Full-bleed black: a post's photos in their real shape, swipeable when
/// there are several, or the profile picture. Caption, Like, Reply in chat.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({super.key, required this.viewModel});

  final PhotoViewerViewModel viewModel;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  static const _dot = 6.0;

  late final PageController _pages = PageController(
    initialPage: widget.viewModel.initialIndex,
  );
  late int _index = widget.viewModel.initialIndex;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: ViewerColors.background,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: viewModel.changes,
            builder: (context, _) {
              final character = viewModel.character;
              final post = viewModel.post;
              if (character == null || post == null) {
                return const SizedBox.shrink();
              }
              final photos = post.photos;
              return Padding(
                padding: const EdgeInsets.only(bottom: Dimens.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimens.spaceS,
                        Dimens.spaceS,
                        Dimens.spaceL,
                        Dimens.spaceS,
                      ),
                      child: Row(
                        spacing: Dimens.spaceSm,
                        children: [
                          IconButton(
                            tooltip: 'Close',
                            style: IconButton.styleFrom(
                              minimumSize: const Size.square(
                                Dimens.minTapTarget,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: () => context.pop(),
                            icon: const AppIcon(
                              AppIconName.close,
                              color: ViewerColors.ink,
                            ),
                          ),
                          Expanded(
                            child: PostHead(
                              character: character,
                              meta: postMetaLabel(post, DateTime.now()),
                              isOnDark: true,
                            ),
                          ),
                          if (photos.length > 1)
                            Text(
                              '${_index + 1} / ${photos.length}',
                              style: const TextStyle(
                                color: ViewerColors.ink,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: photos.isEmpty
                          ? Center(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.asset(
                                  character.portraitAsset,
                                  fit: BoxFit.cover,
                                  semanticLabel:
                                      '${character.name}’s profile picture',
                                ),
                              ),
                            )
                          : PageView(
                              controller: _pages,
                              onPageChanged: (index) =>
                                  setState(() => _index = index),
                              children: [
                                for (final photo in photos)
                                  Center(
                                    child: Semantics(
                                      image: true,
                                      label: 'Photo: ${photo.description}',
                                      child: AspectRatio(
                                        aspectRatio: photoAspectRatio(
                                          photo.shape,
                                        ),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: Illustrations.scene(
                                              photo.scene,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    if (photos.length > 1)
                      ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.only(top: Dimens.spaceM),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: Dimens.spaceXs,
                            children: [
                              for (var i = 0; i < photos.length; i++)
                                Container(
                                  width: _dot,
                                  height: _dot,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: i == _index
                                        ? ViewerColors.ink
                                        : ViewerColors.dot,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimens.gutter,
                        Dimens.spaceL,
                        Dimens.gutter,
                        Dimens.spaceS,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            post.text,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: ViewerColors.ink,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              height: 1.6,
                            ),
                          ),
                          PostStats(likeCount: post.likeCount, isOnDark: true),
                          PostActions(
                            isLiked: post.isLiked,
                            isOnDark: true,
                            onLike: viewModel.toggleLike.execute,
                            onReply: () => context.push<void>(
                              Routes.chat(viewModel.characterId),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
