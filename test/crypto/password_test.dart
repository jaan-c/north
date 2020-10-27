import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:north/src/crypto/crypto.dart';

void main() {
  setUpAll(initCrypto);

  test(
      "derivePasswordHash creates a hash verifiable with verifyPasswordWithHash with the same password.",
      () {
    final password = "Password";
    final wrongPassword = "Wrong Password";
    final hash = derivePasswordHash(password);

    expect(verifyPasswordWithHash(password, hash), isTrue);
    expect(verifyPasswordWithHash(wrongPassword, hash), isFalse);
  });

  test("generateSalt returns a 128 bit random salt.", () {
    final salt1 = generateSalt();
    final salt2 = generateSalt();

    expect(salt1, isNot(equals(salt2)));
    expect([salt1, salt2], everyElement(hasLength(16)));
  });

  test("deriveKeyFromPassword returns the same key for the same inputs.", () {
    final password = "Password";
    final salt1 = generateSalt();
    final salt2 = generateSalt();
    final sameKey1 = deriveKeyFromPassword(password, salt1);
    final sameKey2 = deriveKeyFromPassword(password, salt1);
    final otherKey = deriveKeyFromPassword(password, salt2);

    expect(sameKey1, sameKey2);
    expect(sameKey1, isNot(equals(otherKey)));
  });

  test("deriveKeyFromPassword is compatible with stream cryptos.", () {
    expect(deriveKeyFromPassword("Password", generateSalt()),
        hasLength(Sodium.cryptoSecretstreamXchacha20poly1305Keybytes));
  });
}
