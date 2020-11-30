import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'file_store.dart';

class MediaStore with FileStore {
  @override
  final Uint8List key;

  @override
  final Directory fileDir;

  @override
  final Directory cacheDir;

  MediaStore(
      {@required this.key,
      @required Directory mediaDir,
      @required this.cacheDir})
      : fileDir = mediaDir;
}
