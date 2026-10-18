import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../utils/result.dart';

typedef PhotoData = ({String id, Uint8List thumbnail});

class PhotoLibraryService {
  static const pageSize = 60;

  Future<Result<List<PhotoData>>> getPhotos(int page) async {
    try {
      final permission = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.image,
            mediaLocation: false,
          ),
        ),
      );
      if (!permission.hasAccess) {
        return Result.error(PlatformException(code: 'photo_access_denied'));
      }
      final assets = await PhotoManager.getAssetListPaged(
        page: page,
        pageCount: pageSize,
        type: RequestType.image,
      );
      final photos = await Future.wait([
        for (final asset in assets)
          () async {
            final thumbnail = await asset.thumbnailDataWithSize(
              const ThumbnailSize.square(240),
            );
            return thumbnail == null
                ? null
                : (id: asset.id, thumbnail: thumbnail);
          }(),
      ]);
      return Result.ok(photos.nonNulls.toList());
    } on PlatformException catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<List<String>>> getImagePaths(List<String> ids) async {
    try {
      final paths = <String>[];
      for (final id in ids) {
        final asset = await AssetEntity.fromId(id);
        final file = await asset?.file;
        if (file == null) {
          return Result.error(PlatformException(code: 'photo_unavailable'));
        }
        paths.add(file.path);
      }
      return Result.ok(paths);
    } on PlatformException catch (error) {
      return Result.error(error);
    }
  }

  Future<Result<void>> openSettings() async {
    try {
      await PhotoManager.openSetting();
      return const Result.ok(null);
    } on PlatformException catch (error) {
      return Result.error(error);
    }
  }
}
