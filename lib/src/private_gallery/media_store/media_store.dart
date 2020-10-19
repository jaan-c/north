import 'dart:async';

import 'package:ext_storage/ext_storage.dart';
import 'package:file/chroot.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as pathlib;

import '../commons.dart';

class MediaStoreException implements Exception {
  final String message;
  MediaStoreException(this.message);
  String toString() => "MediaStoreException: $message";
}

class MediaStore {
  static const _mediaDirectoryName = ".north";

  final Future<FileSystem> _futureFileSystem;
  final String _password;

  MediaStore({@required String password, FileSystem fileSystem})
      : _password = password,
        _futureFileSystem = fileSystem != null
            ? Future.value(fileSystem)
            : _joinPathParts(ExtStorage.getExternalStorageDirectory(),
                    _mediaDirectoryName)
                .then((mediaDir) =>
                    ChrootFileSystem(LocalFileSystem(), mediaDir));

  Future<String> put(Uuid id, Stream<List<int>> content) async {
    throw UnimplementedError(_password);
  }

  Stream<List<int>> get(Uuid id, String salt) async* {
    throw UnimplementedError();
  }

  Future<void> delete(Uuid id) async {
    final fileSystem = await _futureFileSystem;

    try {
      fileSystem.file(id.toString()).delete();
    } on FileSystemException catch (e) {
      throw MediaStoreException("Failed to delete $id: ${e.message}");
    }
  }
}

Future<String> _joinPathParts(
    FutureOr<String> part1, FutureOr<String> part2) async {
  final p1 = await part1;
  final p2 = await part2;

  return pathlib.join(p1, p2);
}
