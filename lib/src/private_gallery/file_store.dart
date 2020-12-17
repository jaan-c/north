import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:north/crypto.dart';
import 'package:north/private_gallery.dart';

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
  Uint8List get key;

  @protected
  Directory get fileDir;

  @protected
  Directory get cacheDir;

  Future<bool> has(Uuid id) async {
    return fileDir.file(id.asString).exists();
  }

  CancelableFuture<void> put(Uuid id, File file) {
    final chunkStream = file.openRead();
    return putStream(id, chunkStream);
  }

  CancelableFuture<void> putStream(Uuid id, Stream<List<int>> chunkStream) {
    return CancelableFuture(
        (state) => _encryptAndStore(id, chunkStream, state));
  }

  Future<void> _encryptAndStore(
      Uuid id, Stream<List<int>> plainStream, CancelState state) async {
    if (await has(id)) {
      throw FileStoreException('File $id already exists.');
    }

    final outFile = fileDir.file(id.asString);

    final outSink = outFile.openWrite();
    final cipherStream = encryptStream(key, plainStream);
    try {
      await for (final cipher in cipherStream) {
        state.checkIsCancelled();
        outSink.add(cipher);
      }
      await outSink.flush();
    } on CancelledException catch (_) {
      await outFile.delete();
      rethrow;
    } finally {
      await outSink.close();
    }
  }

  CancelableFuture<void> duplicate(Uuid id, Uuid duplicateId) {
    return CancelableFuture((state) => _duplicateFile(id, duplicateId, state));
  }

  Future<void> _duplicateFile(
      Uuid id, Uuid duplicateId, CancelState state) async {
    if (!await has(id)) {
      throw FileStoreException('File $id does not exist.');
    } else if (await has(duplicateId)) {
      throw FileStoreException('File $duplicateId already exists.');
    }

    final chunkStream = fileDir.file(id.asString).openRead();
    final duplicateFile = fileDir.file(duplicateId.asString);
    final duplicateSink = duplicateFile.openWrite();

    try {
      await for (final chunk in chunkStream) {
        state.checkIsCancelled();
        duplicateSink.add(chunk);
      }
      await duplicateSink.flush();
    } catch (e) {
      await duplicateFile.delete();
      rethrow;
    } finally {
      await duplicateSink.close();
    }
  }

  CancelableFuture<File> get(Uuid id) {
    return CancelableFuture((state) => _decryptAndCache(id, state));
  }

  Future<File> _decryptAndCache(Uuid id, CancelState state) async {
    if (!await has(id)) {
      throw FileStoreException('File $id does not exist.');
    }

    final cipherFile = fileDir.file(id.asString);
    final cacheFile = await cacheDir.file(id.asString);

    if (await cacheFile.exists()) {
      return cacheFile;
    }

    final cipherStream = cipherFile.openRead();
    final plainStream = decryptStream(key, cipherStream);
    final cacheSink = cacheFile.openWrite();
    try {
      await for (final plain in plainStream) {
        state.checkIsCancelled();
        cacheSink.add(plain);
      }
      await cacheSink.flush();
    } on CancelledException catch (_) {
      await cacheFile.delete();
      rethrow;
    } finally {
      await cacheSink.close();
    }

    return cacheFile;
  }

  Future<void> delete(Uuid id) async {
    final cipherFile = fileDir.file(id.asString);
    final cacheFile = await cacheDir.file(id.asString);

    await cipherFile.deleteOrNoop();
    await cacheFile.deleteOrNoop();
  }

  Future<void> clearCache() async {
    await cacheDir.delete(recursive: true);
  }
}

extension _DeleteOrNoop on File {
  /// Delete this file. Noop if it already doesn't exist.
  Future<void> deleteOrNoop({bool recursive = false}) async {
    try {
      await delete(recursive: recursive);
    } on FileSystemException catch (e) {
      // If not 'ENOENT: No such file or directory'.
      if (e.osError.errorCode != 2) {
        rethrow;
      }
    }
  }
}
