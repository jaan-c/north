import 'dart:io';

import 'package:image/image.dart';
import 'package:mime/mime.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class GenerateThumbnailException implements Exception {
  final String message;
  GenerateThumbnailException(this.message);
  @override
  String toString() => 'GenerateThumbnailException: $message';
}

/// Generate a square thumbnail from [media] in [size] pixels. The thumbnail is
/// JPG encoded and returned as bytes.
Future<List<int>> generateThumbnail(File media,
    {int size = 200, quality = 80}) async {
  if (await _isVideoOrGif(media)) {
    return _generateVideoThumbnail(media, size, quality);
  } else if (await _isImage(media)) {
    return _generateImageThumbnail(media, size, quality);
  } else {
    throw GenerateThumbnailException('media is neither an image or video');
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

Future<bool> _isImage(File media) async {
  final header = await _readHeader(media);
  final mime = lookupMimeType(media.path, headerBytes: header);
  return mime.startsWith('image');
}

Future<bool> _isVideoOrGif(File media) async {
  final header = await _readHeader(media);
  final mime = lookupMimeType(media.path, headerBytes: header);
  return mime.startsWith('video') || mime == 'image/gif';
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
