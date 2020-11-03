import 'dart:async';
import 'dart:io';

import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as pathlib;

import 'file_store.dart';
import 'utils.dart';

class MediaStore with FileStore {
  static const _mediaDirectoryName = '.north';
  static const _mediaCacheDirectoryName = 'media_cache';

  @override
  final String password;

  @override
  final Future<Directory> futureMediaDir;

  @override
  final Future<Directory> futureCacheDir;

  MediaStore._internal(this.password, this.futureMediaDir, this.futureCacheDir);

  factory MediaStore(
      {@required String password,
      Directory externalRoot,
      Directory cacheRoot}) {
    final cacheDir =
        createCacheDir(_mediaCacheDirectoryName, cacheRoot: cacheRoot);

    if (externalRoot != null) {
      return MediaStore._internal(
          password, Future.value(externalRoot), cacheDir);
    }

    return MediaStore._internal(password, (() async {
      externalRoot ??=
          Directory(await ExtStorage.getExternalStorageDirectory());
      return Directory(pathlib.join(externalRoot.path, _mediaDirectoryName))
          .create();
    })(), cacheDir);
  }
}
