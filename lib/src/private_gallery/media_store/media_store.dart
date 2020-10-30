import 'dart:async';
import 'dart:typed_data';

import 'package:ext_storage/ext_storage.dart';
import 'package:file/chroot.dart';
import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:flutter/foundation.dart';
import 'package:north/crypto.dart';
import 'package:path/path.dart' as pathlib;

import '../commons.dart';

class MediaStoreException implements Exception {
  final String message;
  MediaStoreException(this.message);
  @override
  String toString() => 'MediaStoreException: $message';
}

class MediaStore {
  static const _mediaDirectoryName = '.north';

  final Future<FileSystem> _futureFileSystem;
  final String _password;

  MediaStore._internal(this._password, this._futureFileSystem);

  factory MediaStore({@required String password, FileSystem fileSystem}) {
    if (fileSystem != null) {
      return MediaStore._internal(password, Future.value(fileSystem));
    }

    return MediaStore._internal(password, (() async {
      final encryptedRoot = pathlib.join(
          await ExtStorage.getExternalStorageDirectory(), _mediaDirectoryName);
      return ChrootFileSystem(LocalFileSystem(), encryptedRoot);
    })());
  }

  Future<Uint8List> put(Uuid id, Stream<List<int>> content) async {
    final fileSystem = await _futureFileSystem;
    final file = fileSystem.file(id.toString());

    if (await file.exists()) {
      throw MediaStoreException('Media $id already exists.');
    }

    final sink = file.openWrite();
    final salt = generateSalt();
    try {
      final cipherStream = encryptStream(_password, salt, content);
      await sink.addStream(cipherStream);
      await sink.flush(); // Call only if addStream completes.
    } finally {
      await sink.close();
    }

    return salt;
  }

  Stream<List<int>> get(Uuid id, Uint8List salt) async* {
    final fileSystem = await _futureFileSystem;
    final file = fileSystem.file(id.toString());

    if (!await file.exists()) {
      throw MediaStoreException('Media $id does not exist.');
    }

    final cipherStream = file.openRead();
    yield* decryptStream(_password, salt, cipherStream);
  }

  Future<void> delete(Uuid id) async {
    final fileSystem = await _futureFileSystem;

    try {
      await fileSystem.file(id.toString()).delete();
    } on FileSystemException catch (e) {
      throw MediaStoreException('Failed to delete media $id: ${e.message}');
    }
  }
}
