import 'dart:io';

import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as pathlib;

import 'file_store.dart';
import 'utils.dart';

class ThumbnailStore with FileStore {
  static const _thumbnailDirPath = '.north/thumbnails';
  static const _cacheDirName = 'media_thumbnails';

  @override
  final String password;

  @override
  final Future<Directory> futureMediaDir;

  @override
  final Future<Directory> futureCacheDir;

  ThumbnailStore._internal(
      this.password, this.futureMediaDir, this.futureCacheDir);

  factory ThumbnailStore(
      {@required String password,
      Directory externalRoot,
      Directory cacheRoot}) {
    final cacheDir = createCacheDir(_cacheDirName, cacheRoot: cacheRoot);

    if (externalRoot != null) {
      return ThumbnailStore._internal(
          password, Future.value(externalRoot), cacheDir);
    }

    return ThumbnailStore._internal(password, (() async {
      externalRoot ??=
          Directory(await ExtStorage.getExternalStorageDirectory());

      return Directory(pathlib.join(externalRoot.path, _thumbnailDirPath))
          .create(recursive: true);
    })(), cacheDir);
  }
}
