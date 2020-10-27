import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:north/src/crypto/crypto.dart';
import 'package:north/src/crypto/stream.dart';

import '../utils.dart';

void main() {
  setUpAll(initCrypto);

  test("encryptStream and decryptStream.", () async {
    final password = "Password";
    final salt = generateSalt();
    final message = randomMessage(10, 1024, 2048);

    final cipherStream =
        encryptStream(password, salt, Stream.fromIterable(message));
    final plainStream = decryptStream(password, salt, cipherStream);
    expect((await plainStream.collect()).flatten(), message.flatten());
  });
}

List<Uint8List> randomMessage(int length, int minChunkSize, int maxChunkSize) {
  final message = <Uint8List>[];
  for (var i = 0; i < length; i++) {
    final size = randomInt(min: minChunkSize, max: maxChunkSize);
    message.add(randomBytes(size));
  }

  return message;
}

extension Collect<T> on Stream<T> {
  Future<List<T>> collect() async {
    return [await for (final e in this) e];
  }
}

extension Flatten<T> on Iterable<Iterable<T>> {
  Iterable<T> flatten() {
    return this.expand((e) => e);
  }
}
