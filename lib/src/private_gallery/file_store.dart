import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:north/crypto.dart';
import 'package:north/src/private_gallery/cancelable_future.dart';

import 'file_system_utils.dart';
import 'uuid.dart';

class FileStoreException implements Exception {
  final String message;
  FileStoreException(this.message);
  @override
  String toString() => '${(FileStoreException)}: $message';
}

mixin FileStore {
  @protected
  String get password;

  @protected
  Future<Directory> get futureMediaDir;

  @protected
  Future<Directory> get futureCacheDir;

  Future<bool> has(Uuid id) async {
    final mediaDir = await futureMediaDir;
    return mediaDir.file(id.asString).exists();
  }

  CancelableFuture<List<int>> put(Uuid id, File file) {
    return CancelableFuture((state) => _encryptAndStore(id, file, state));
  }

  Future<List<int>> _encryptAndStore(
      Uuid id, File file, CancelState state) async {
    if (await has(id)) {
      throw FileStoreException('File $id already exists.');
    }

    final mediaDir = await futureMediaDir;
    final inFile = file;
    final outFile = mediaDir.file(id.asString);

    final outSink = outFile.openWrite();
    final salt = generateSalt();
    final plainStream = inFile.openRead();
    final cipherStream = encryptStream(password, salt, plainStream);
    try {
      await for (final cipher in cipherStream) {
        state.checkIsCancelled();
        outSink.add(cipher);
      }
      await outSink.flush();
    } on CancelledOperationException catch (_) {
      await outFile.delete();
      rethrow;
    } finally {
      await outSink.close();
    }

    return salt;
  }

  CancelableFuture<File> get(Uuid id, List<int> salt) {
    return CancelableFuture((state) => _decryptAndCache(id, salt, state));
  }

  Future<File> _decryptAndCache(
      Uuid id, List<int> salt, CancelState state) async {
    if (!await has(id)) {
      throw FileStoreException('File $id does not exist.');
    }

    final mediaDir = await futureMediaDir;
    final cacheDir = await futureCacheDir;

    final cipherFile = mediaDir.file(id.asString);
    final cacheFile = await cacheDir.file(id.asString);

    if (await cacheFile.exists()) {
      return cacheFile;
    }

    final cipherStream = cipherFile.openRead();
    final plainStream = decryptStream(password, salt, cipherStream);
    final cacheSink = cacheFile.openWrite();
    try {
      await for (final plain in plainStream) {
        state.checkIsCancelled();
        cacheSink.add(plain);
      }
      await cacheSink.flush();
    } on CancelledOperationException catch (_) {
      await cacheFile.delete();
      rethrow;
    } finally {
      await cacheSink.close();
    }

    return cacheFile;
  }

  Future<void> delete(Uuid id) async {
    final mediaDir = await futureMediaDir;
    final cacheDir = await futureCacheDir;

    final cipherFile = mediaDir.file(id.asString);
    final cacheFile = await cacheDir.file(id.asString);

    await cipherFile.delete();
    await cacheFile.delete();
  }

  Future<void> clearCache() async {
    final cacheDir = await futureCacheDir;
    await cacheDir.delete(recursive: true);
  }
}
