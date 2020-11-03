import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:north/crypto.dart';

import 'file_store_exception.dart';
import 'utils.dart';
import 'uuid.dart';

mixin FileStore {
  @protected
  String get password;

  @protected
  Future<Directory> get futureMediaDir;

  @protected
  Future<Directory> get futureCacheDir;

  Future<bool> has(Uuid id) async {
    final mediaDir = await futureMediaDir;
    return mediaDir.file(id.toString()).exists();
  }

  Future<List<int>> put(Uuid id, File file) async {
    if (await has(id)) {
      throw FileStoreException('File $id already exists.');
    }

    final mediaDir = await futureMediaDir;
    final inFile = file;
    final outFile = mediaDir.file(id.toString());

    final outSink = outFile.openWrite();
    final salt = generateSalt();
    final plainStream = inFile.openRead();
    final cipherStream = encryptStream(password, salt, plainStream);
    try {
      await outSink.addStream(cipherStream);
      await outSink.flush(); // Call only if addStream completes.
    } finally {
      await outSink.close();
    }

    return salt;
  }

  Future<File> get(Uuid id, List<int> salt) async {
    if (!await has(id)) {
      throw FileStoreException('File $id does not exist.');
    }

    final mediaDir = await futureMediaDir;
    final cacheDir = await futureCacheDir;

    final cipherFile = mediaDir.file(id.toString());
    final cacheFile = await cacheDir.file(id.toString());

    if (await cacheFile.exists()) {
      return cacheFile;
    }

    final cipherStream = cipherFile.openRead();
    final plainStream = decryptStream(password, salt, cipherStream);
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
    final mediaDir = await futureMediaDir;
    final cacheDir = await futureCacheDir;

    final cipherFile = mediaDir.file(id.toString());
    final cacheFile = await cacheDir.file(id.toString());

    await cipherFile.delete();
    await cacheFile.delete();
  }

  Future<void> clearCache() async {
    final cacheDir = await futureCacheDir;
    await cacheDir.delete(recursive: true);
  }
}