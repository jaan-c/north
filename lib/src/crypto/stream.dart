import 'dart:ffi';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

import 'crypto.dart';

final _headerSize = Sodium.cryptoSecretstreamXchacha20poly1305Headerbytes;
final _authSize = Sodium.cryptoSecretstreamXchacha20poly1305Abytes;
final _messageTag = Sodium.cryptoSecretstreamXchacha20poly1305TagMessage;
final _finalTag = Sodium.cryptoSecretstreamXchacha20poly1305TagFinal;

class CryptoException implements Exception {
  final String message;
  CryptoException(this.message);
  String toString() => "CryptoException: $message";
}

Stream<Uint8List> encryptStream(
    String password, Uint8List salt, Stream<Uint8List> plainStream) async* {
  final key = deriveKeyFromPassword(password, salt);

  final result = Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);
  yield result.header;

  yield* plainStream.rechunk(_headerSize - _authSize).withPosition().map(
      (plain) => Sodium.cryptoSecretstreamXchacha20poly1305Push(result.state,
          plain.value, null, plain.isLast ? _finalTag : _messageTag));
}

Stream<Uint8List> decryptStream(
    String password, Uint8List salt, Stream<Uint8List> cipherStream) async* {
  final key = deriveKeyFromPassword(password, salt);

  Pointer<Uint8> state;
  await for (final cipher in cipherStream.rechunk(_headerSize).withPosition()) {
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

class _ChunkPosition {
  final Uint8List value;
  final bool isLast;
  _ChunkPosition({@required this.value, @required this.isLast});
}

extension _ChunkStreamX on Stream<Uint8List> {
  Stream<Uint8List> rechunk(int size) async* {
    final buffer = <int>[];
    final flatStream = this.expand((bytes) => bytes);
    await for (final byte in flatStream) {
      if (buffer.length == size) {
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
      if (before == null) {
        before = chunk;
        continue;
      }
      yield _ChunkPosition(value: before, isLast: false);
      before = chunk;
    }

    yield _ChunkPosition(value: before, isLast: true);
  }
}
