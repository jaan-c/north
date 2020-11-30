import 'dart:io';

import 'package:path/path.dart' as pathlib;

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
