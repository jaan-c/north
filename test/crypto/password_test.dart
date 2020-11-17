import 'package:flutter_test/flutter_test.dart';
import 'package:north/crypto.dart';

void main() {
  setUpAll(initCrypto);

  test(
      'derivePasswordHash creates a hash verifiable with verifyPasswordWithHash with the same password.',
      () {
    final password = 'Password';
    final wrongPassword = 'Wrong Password';
    final hash = derivePasswordHash(password);

    expect(verifyPasswordWithHash(password, hash), isTrue);
    expect(verifyPasswordWithHash(wrongPassword, hash), isFalse);
  });

  test('generateSalt returns a 128 bit random salt.', () {
    final salt1 = generateSalt();
    final salt2 = generateSalt();

    expect(salt1, isNot(equals(salt2)));
    expect([salt1, salt2], everyElement(hasLength(16)));
  });

  test('deriveKeyFromPassword creates a 256 bit key from password and salt.',
      () {
    final password = 'Password';
    final salt = generateSalt();
    final key1 = deriveKeyFromPassword(password, salt);
    final key2 = deriveKeyFromPassword(password, salt);

    expect(key1, hasLength(32));
    expect(key2, hasLength(32));
    expect(key1, key2);
  });
}
