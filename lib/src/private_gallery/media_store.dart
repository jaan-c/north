import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:ext_storage/ext_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:north/crypto.dart';
import 'package:path/path.dart' as pathlib;

import 'utils.dart';
import 'uuid.dart';

class MediaStoreException implements Exception {
  final String message;
  MediaStoreException(this.message);
  @override
  String toString() => 'MediaStoreException: $message';
}

class MediaStore {
  static const _mediaDirectoryName = '.north';
  static const _mediaCacheDirectoryName = 'media_cache';

  final String _password;
  final Future<Directory> _futureMediaDir;
  final Future<Directory> _futureCacheDir;

  MediaStore._internal(
      this._password, this._futureMediaDir, this._futureCacheDir);

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

  Future<Uint8List> put(Uuid id, File file) async {
    final mediaDir = await _futureMediaDir;
    final inFile = file;
    final outFile = mediaDir.file(id.toString());

    if (await outFile.exists()) {
      throw MediaStoreException('Media $id already exists.');
    }

    final outSink = outFile.openWrite();
    final salt = generateSalt();
    final plainStream = inFile.openRead();
    final cipherStream = encryptStream(_password, salt, plainStream);
    try {
      await outSink.addStream(cipherStream);
      await outSink.flush(); // Call only if addStream completes.
    } finally {
      await outSink.close();
    }

    return salt;
  }

  Future<File> get(Uuid id, Uint8List salt) async {
    final mediaDir = await _futureMediaDir;
    final cacheDir = await _futureCacheDir;

    final cipherFile = mediaDir.file(id.toString());
    final cacheFile = await cacheDir.file(id.toString());

    if (!await cipherFile.exists()) {
      throw MediaStoreException('Media $id does not exist.');
    }

    if (await cacheFile.exists()) {
      return cacheFile;
    }

    final cipherStream = cipherFile.openRead();
    final plainStream = decryptStream(_password, salt, cipherStream);
    final cacheSink = cacheFile.openWrite();
    try {
      await cacheSink.addStream(plainStream);
      await cacheSink.flush();
    } finally {
      await cacheSink.close();
    }

    return cacheFile;
  }

  Future<void> delete(Uuid id) async {
    final mediaDir = await _futureMediaDir;
    final cacheDir = await _futureCacheDir;

    final cipherFile = mediaDir.file(id.toString());
    final cacheFile = await cacheDir.file(id.toString());

    await cipherFile.delete();
    await cacheFile.delete();
  }

  Future<void> clearCache() async {
    final cacheDir = await _futureCacheDir;
    await cacheDir.delete(recursive: true);
  }
}
