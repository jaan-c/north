import 'package:flutter_test/flutter_test.dart';
import 'package:north/crypto.dart';

import '../utils.dart';

void main() {
  final password = 'Password';
  List<int> salt;

  setUpAll(() {
    initCrypto();
    salt = generateSalt();
  });

  test('encryptStream and decryptSream rejects empty password', () async {
    final emptyPassword = '';
    final stream = Stream.fromIterable([randomBytes(1024)]);

    await expectLater(encryptStream(emptyPassword, salt, stream),
        emitsError(isInstanceOf<ArgumentError>()));
    await expectLater(decryptStream(emptyPassword, salt, stream),
        emitsError(isInstanceOf<ArgumentError>()));
  });

  test('encryptStream and decryptStream rejects salt shorter than 16 bytes.',
      () async {
    final shortSalt = randomBytes(15);
    final stream = Stream.fromIterable([randomBytes(1024)]);

    await expectLater(encryptStream(password, shortSalt, stream),
        emitsError(isInstanceOf<ArgumentError>()));
    await expectLater(decryptStream(password, shortSalt, stream),
        emitsError(isInstanceOf<ArgumentError>()));
  });

  test('encryptStream with the same inputs yields different outputs.',
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

  test('encryptStream and decryptStream handles zero stream properly.',
      () async {
    final cipherStream = encryptStream(password, salt, Stream.fromIterable([]));
    final plainStream = decryptStream(password, salt, cipherStream);

    expect(await plainStream.collect(), <List<int>>[]);
  });

  test('encryptStream and decryptStream.', () async {
    final message = randomBytes(2000000);

    final cipherStream =
        encryptStream(password, salt, Stream.fromIterable([message]));
    final plainStream = decryptStream(password, salt, cipherStream);
    expect(await plainStream.collect(), message);
  });

  test('decryptStream throws CryptoException on failure.', () async {
    final invalidCipherStream = Stream.fromIterable([randomBytes(2000000)]);

    await expectLater(
        decryptStream(password, salt, invalidCipherStream).collect(),
        emitsInOrder(
            [emits(anything), emitsError(isInstanceOf<CryptoException>())]));
  });
}

extension Collect<T> on Stream<Iterable<T>> {
  Future<List<T>> collect() async {
    return [await for (final x in expand((xs) => xs)) x];
  }
}

extension Flatten<T> on Iterable<Iterable<T>> {
  Iterable<T> flatten() {
    return expand((e) => e);
  }
}
