import 'dart:io';

import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';

Future<Directory> createCacheDir(String name, {Directory cacheRoot}) async {
  cacheRoot = cacheRoot ??
      (await getExternalCacheDirectories())
          .firstWhere((dir) => pathlib.isWithin('/storage/emulated', dir.path));

  return cacheRoot.directory(name).create();
}

extension FileSystemEntityWithin on Directory {
  /// Return a [File] with [name] inside [Directory].
  File file(String name) {
    return File(pathlib.join(path, name));
  }

  /// Return a [Directory] with [name] inside [Directory].
  Directory directory(String name) {
    return Directory(pathlib.join(path, name));
  }
}
