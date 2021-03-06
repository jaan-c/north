import 'package:flutter_test/flutter_test.dart';
import 'package:north/crypto.dart';

void main() {
  test(
      'derivePasswordHash creates a hash verifiable with verifyPasswordWithHash with the same password.',
      () async {
    final password = 'Password';
    final wrongPassword = 'Wrong Password';
    final hash = await derivePasswordHash(password);

    await expectLater(verifyPassword(password, hash), completion(isTrue));
    await expectLater(verifyPassword(wrongPassword, hash), completion(isFalse));
  });

  test('generateSalt returns a 128 bit random salt.', () {
    final salt1 = generateSalt();
    final salt2 = generateSalt();

    expect(salt1, isNot(equals(salt2)));
    expect([salt1, salt2], everyElement(hasLength(16)));
  });

  test('deriveKey creates a 256 bit key from password and salt.', () async {
    final password = 'Password';
    final salt = generateSalt();
    final key1 = await deriveKey(password, salt);
    final key2 = await deriveKey(password, salt);

    expect(key1, hasLength(32));
    expect(key2, hasLength(32));
    expect(key1, key2);
  });
}
