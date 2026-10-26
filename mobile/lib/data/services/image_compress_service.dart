import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../utils/result.dart';

/// Shrinks phone photos before they're uploaded.
class ImageCompressService {
  /// The photo at [path] as a JPEG whose shorter side is at most 1200 px, so
  /// a 4:3 photo comes out 1600 × 1200. HEIC works too.
  Future<Result<Uint8List>> jpeg(String path) async {
    if (!await File(path).exists()) {
      return Result.error(FileSystemException('Photo not found', path));
    }
    try {
      final bytes = await FlutterImageCompress.compressWithFile(
        path,
        minWidth: 1200,
        minHeight: 1200,
        quality: 85,
      );
      return bytes == null
          ? Result.error(PlatformException(code: 'compress_failed'))
          : Result.ok(bytes);
    } on PlatformException catch (error) {
      return Result.error(error);
    }
  }
}
