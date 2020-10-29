import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

final _headerSize = Sodium.cryptoSecretstreamXchacha20poly1305Headerbytes;
final _authSize = Sodium.cryptoSecretstreamXchacha20poly1305Abytes;
final _chunkSize = 1048576; // 1 MB
final _messageTag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
final _finalTag = Sodium.cryptoSecretstreamXchacha20poly1305TagFinal;

final _opsLimit = Sodium.cryptoPwhashOpslimitSensitive;
final _memLimit = Sodium.cryptoPwhashMemlimitSensitive;

class CryptoException implements Exception {
  final String message;
  CryptoException(this.message);
  String toString() => "CryptoException: $message";
}

Stream<Uint8List> encryptStream(
    String password, Uint8List salt, Stream<Uint8List> plainStream) async* {
  final key = _deriveKeyFromPassword(password, salt);

  final result = Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
  yield result.header;

  yield* plainStream.rechunk(chunkSize: _chunkSize).withPosition().map(
      (plain) => Sodium.cryptoSecretstreamXchacha20poly1305Push(result.state,
          plain.value, null, plain.isLast ? _finalTag : _messageTag));
}

Stream<Uint8List> decryptStream(
    String password, Uint8List salt, Stream<Uint8List> cipherStream) async* {
  final key = _deriveKeyFromPassword(password, salt);

  Pointer<Uint8> state;
  await for (final cipher in cipherStream
      .rechunk(headerSize: _headerSize, chunkSize: _chunkSize + _authSize)
      .withPosition()) {
    if (state == null) {
      final header = cipher.value;
      state = Sodium.cryptoSecretstreamXchacha20poly1305InitPull(header, key);
    } else {
      final result = Sodium.cryptoSecretstreamXchacha20poly1305Pull(
          state, cipher.value, null);
      yield result.m;
    }
  }
}

Uint8List _deriveKeyFromPassword(String password, Uint8List salt) {
  return PasswordHash.hashString(password, salt,
      outlen: Sodium.cryptoSecretstreamXchacha20poly1305Keybytes,
      opslimit: _opsLimit,
      memlimit: _memLimit);
}

class _ChunkPosition {
  final Uint8List value;
  final bool isLast;
  _ChunkPosition({@required this.value, @required this.isLast});
}

extension _ChunkStreamTransformer on Stream<Uint8List> {
  Stream<Uint8List> rechunk({@required int chunkSize, int headerSize}) async* {
    headerSize = headerSize ?? chunkSize;

    final buffer = <int>[];
    final flatStream = this.expand((bytes) => bytes);
    var isFirstYield = true;
    await for (final byte in flatStream) {
      if (isFirstYield && buffer.length == headerSize) {
        yield Uint8List.fromList(buffer);
        buffer.clear();
        isFirstYield = false;
      } else if (!isFirstYield && buffer.length == chunkSize) {
        yield Uint8List.fromList(buffer);
        buffer.clear();
      }

      buffer.add(byte);
    }
    yield Uint8List.fromList(buffer);
  }

  Stream<_ChunkPosition> withPosition() async* {
    Uint8List before;
    await for (final chunk in this) {
      if (before != null) {
        yield _ChunkPosition(value: before, isLast: false);
      }
      before = chunk;
    }
    yield _ChunkPosition(value: before, isLast: true);
  }
}
