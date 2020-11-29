import 'dart:io';

import 'package:image/image.dart';
import 'package:mime/mime.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailGeneratorException implements Exception {
  final String message;
  ThumbnailGeneratorException(this.message);
  @override
  String toString() => 'GenerateThumbnailException: $message';
}

/// Generate a square thumbnail from [media] in [size] pixels. The thumbnail is
/// JPG encoded and returned as bytes.
Future<List<int>> generateThumbnail(File media,
    {int size = 200, quality = 80}) async {
  final header = await _readHeader(media);
  final mime = lookupMimeType(media.path, headerBytes: header);

  if (mime.startsWith('video') || mime == 'image/gif') {
    return _generateVideoThumbnail(media, size, quality);
  } else if (mime.startsWith('image')) {
    return _generateImageThumbnail(media, size, quality);
  } else {
    throw ThumbnailGeneratorException(
        '${media.path} is neither image or video');
  }
}

Future<List<int>> _generateImageThumbnail(
    File image, int size, int quality) async {
  final buffer = await decodeImage(await image.readAsBytes());
  final thumbnail = copyResizeCropSquare(buffer, size);
  return encodeJpg(thumbnail, quality: quality);
}

Future<List<int>> _generateVideoThumbnail(
    File video, int size, int quality) async {
  final frame = await VideoThumbnail.thumbnailData(
      video: video.path, imageFormat: ImageFormat.JPEG, quality: 100);
  final buffer = decodeImage(frame);
  final thumbnail = copyResizeCropSquare(buffer, size);
  return encodeJpg(thumbnail, quality: quality);
}

Future<List<int>> _readHeader(File media) async {
  final ram = await media.open();
  try {
    final header = await ram.read(defaultMagicNumbersMaxLength);
    return header;
  } finally {
    await ram.close();
  }
}
