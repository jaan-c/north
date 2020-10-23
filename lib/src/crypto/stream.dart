import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

import 'crypto.dart';

final _headerSize = Sodium.cryptoSecretstreamXchacha20poly1305Headerbytes;

// TODO: Return header since it's needed by decryptStream.
Stream<Uint8List> encryptStream(
    String password, Uint8List salt, Stream<Uint8List> plainStream) async* {
  final key = deriveKeyFromPassword(password, salt);
  final result = Sodium.cryptoSecretstreamXchacha20poly1305InitPush(key);

  await for (final chunk in _readAhead(plainStream)) {
    yield Sodium.cryptoSecretstreamXchacha20poly1305Push(
        result.state,
        chunk.value,
        null,
        chunk.isLast ? Sodium.cryptoSecretstreamXchacha20poly1305TagFinal : 0);
  }
}

Stream<Uint8List> decryptStream(String password, Uint8List salt,
    Uint8List header, Stream<Uint8List> cipherStream) async* {
  final key = deriveKeyFromPassword(password, salt);
  final state = Sodium.cryptoSecretstreamXchacha20poly1305InitPull(header, key);

  await for (final chunk in cipherStream) {
    final result =
        Sodium.cryptoSecretstreamXchacha20poly1305Pull(state, chunk, null);
    yield result.m;
  }
}

class _Message<T> {
  final T value;
  final bool isLast;
  _Message({@required this.value, @required this.isLast});
}

Stream<_Message<T>> _readAhead<T>(Stream<T> stream) async* {
  T before;
  await for (final value in stream) {
    if (before == null) {
      before = value;
    } else {
      yield _Message(value: before, isLast: false);
      before = value;
    }
  }
  yield _Message(value: before, isLast: true);
}
