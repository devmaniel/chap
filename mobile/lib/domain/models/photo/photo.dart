import 'dart:typed_data';

/// A recent library photo ready to preview, identified by its platform ID.
class Photo {
  const Photo({required this.id, required this.thumbnail});

  final String id;
  final Uint8List thumbnail;
}
