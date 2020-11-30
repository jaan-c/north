import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import 'file_store.dart';

class ThumbnailStore with FileStore {
  @override
  final Uint8List key;

  @override
  final Directory fileDir;

  @override
  final Directory cacheDir;

  ThumbnailStore(
      {@required this.key,
      @required Directory thumbnailDir,
      @required this.cacheDir})
      : fileDir = thumbnailDir;
}
