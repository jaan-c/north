import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:north/src/crypto/crypto.dart';
import 'package:north/src/crypto/stream.dart';

import '../utils.dart';

void main() {
  final password = "Password";
  Uint8List salt;

  setUpAll(() {
    initCrypto();
    salt = generateSalt();
  });

  test("encryptStream with the same inputs yields different outputs.",
      () async {
    final message = randomMessage(10, 1024, 2048);
    final cipher1 =
        await encryptStream(password, salt, Stream.fromIterable(message))
            .collect();
    final cipher2 =
        await encryptStream(password, salt, Stream.fromIterable(message))
            .collect();

    expect(cipher1, isNot(equals(cipher2)));
  });

  test("encryptStream and decryptStream handles zero stream properly.",
      () async {
    final message = <Uint8List>[];
    final cipherStream =
        encryptStream(password, salt, Stream.fromIterable(message));
    final plainStream = decryptStream(password, salt, cipherStream);

    expect(await plainStream.collect(), message.flatten());
  });

  test("encryptStream and decryptStream.", () async {
    final message = randomMessage(10, 1024, 2048);

    final cipherStream =
        encryptStream(password, salt, Stream.fromIterable(message));
    final plainStream = decryptStream(password, salt, cipherStream);
    expect(await plainStream.collect(), message.flatten());
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

extension Collect<T> on Stream<Iterable<T>> {
  Future<List<T>> collect() async {
    return [await for (final x in this.expand((xs) => xs)) x];
  }
}

extension Flatten<T> on Iterable<Iterable<T>> {
  Iterable<T> flatten() {
    return this.expand((e) => e);
  }
}
