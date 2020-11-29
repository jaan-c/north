import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';

import 'file_store.dart';
import 'file_system_utils.dart';

class ThumbnailStore with FileStore {
  static const _thumbnailDirName = 'thumbnails';
  static const _cacheDirName = 'thumbnail_cache';

  @override
  final Uint8List key;

  @override
  final Future<Directory> futureFileDir;

  @override
  final Future<Directory> futureCacheDir;

  ThumbnailStore._internal(this.key, this.futureFileDir, this.futureCacheDir);

  factory ThumbnailStore(
      {@required Uint8List key, Directory externalRoot, Directory cacheRoot}) {
    final cacheDir = createCacheDir(_cacheDirName, cacheRoot: cacheRoot);

    if (externalRoot != null) {
      return ThumbnailStore._internal(
          key, Future.value(externalRoot), cacheDir);
    }

    return ThumbnailStore._internal(key, (() async {
      externalRoot ??= await getExternalStorageDirectory();

      return Directory(pathlib.join(externalRoot.path, _thumbnailDirName))
          .create(recursive: true);
    })(), cacheDir);
  }
}
