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
    final message = randomBytes(2000000);
    final cipher1 =
        await encryptStream(password, salt, Stream.fromIterable([message]))
            .collect();
    final cipher2 =
        await encryptStream(password, salt, Stream.fromIterable([message]))
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
    final message = randomBytes(2000000);

    final cipherStream =
        encryptStream(password, salt, Stream.fromIterable([message]));
    final plainStream = decryptStream(password, salt, cipherStream);
    expect(await plainStream.collect(), message);
  });
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
