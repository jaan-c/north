import 'package:file/file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:north/crypto.dart';

import '../utils.dart';

void main() {
  final key = deriveKey('Password', generateSalt());

  setUpAll(initCrypto);

  test(
      'encryptStream with the same key and plainStream yields different outputs.',
      () async {
    final message = randomBytes(2000000);
    final cipher1 =
        await encryptStream(key, Stream.fromIterable([message])).collect();
    final cipher2 =
        await encryptStream(key, Stream.fromIterable([message])).collect();

    expect(cipher1, isNot(equals(cipher2)));
  });

  test('encryptStream and decryptStream handles zero stream properly.',
      () async {
    final cipherStream = encryptStream(key, Stream.fromIterable([]));
    final plainStream = decryptStream(key, cipherStream);

    expect(await plainStream.collect(), <List<int>>[]);
  });

  test('encryptStream and decryptStream.', () async {
    final message = randomBytes(2000000);

    final cipherStream = encryptStream(key, Stream.fromIterable([message]));
    final plainStream = decryptStream(key, cipherStream);
    expect(await plainStream.collect(), message);
  });

  test('decryptStream throws CryptoException on failure.', () async {
    final invalidCipherStream = Stream.fromIterable([randomBytes(2000000)]);

    await expectLater(decryptStream(key, invalidCipherStream).collect(),
        throwsA(isInstanceOf<CryptoException>()));
  });

  test('encryptStream and decryptStream handles error streams properly.',
      () async {
    final errorStream = () => Stream<List<int>>.error(
        FileSystemException('Terrible things happened.'));

    await expectLater(encryptStream(key, errorStream()).collect(),
        throwsA(isInstanceOf<CryptoException>()));
    await expectLater(decryptStream(key, errorStream()).collect(),
        throwsA(isInstanceOf<CryptoException>()));
  });

  test('encryptStream cleans up properly on partial consumption.', () async {
    final plainStream = Stream.fromIterable([randomBytes(8000000)]);
    final cipherStream = encryptStream(key, plainStream);

    await expectLater(cipherStream.take(2).collect(), completes);
  });

  test('decryptStream cleans up properly on partial consumption.', () async {
    final plainStream = Stream.fromIterable([randomBytes(8000000)]);
    final cipherStream = encryptStream(key, plainStream);
    final decryptedStream = decryptStream(key, cipherStream);

    await expectLater(decryptedStream.take(2).collect(), completes);
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
