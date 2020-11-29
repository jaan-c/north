import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'file_store.dart';
import 'file_system_utils.dart';

class MediaStore with FileStore {
  static const _mediaDirName = 'medias';
  static const _cacheDirName = 'media_cache';

  @override
  final Uint8List key;

  @override
  final Future<Directory> futureFileDir;

  @override
  final Future<Directory> futureCacheDir;

  MediaStore._internal(this.key, this.futureFileDir, this.futureCacheDir);

  factory MediaStore(
      {@required Uint8List key, Directory appRoot, Directory cacheRoot}) {
    final cacheDir = createCacheDir(_cacheDirName, cacheRoot: cacheRoot);

    if (appRoot != null) {
      return MediaStore._internal(key, Future.value(appRoot), cacheDir);
    }

    return MediaStore._internal(key, (() async {
      appRoot ??= await getExternalStorageDirectory();
      return appRoot.directory(_mediaDirName).create(recursive: true);
    })(), cacheDir);
  }
}
