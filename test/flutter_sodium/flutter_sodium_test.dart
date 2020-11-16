import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(Sodium.init);

  test('Version is 1.0.18', () {
    expect(Sodium.versionString, '1.0.18');
  });

  test('cryptoSecretstreamXchacha20poly1305Keybytes is 256 bits', () {
    expect(Sodium.cryptoSecretstreamXchacha20poly1305Keybytes, 32);
  });

  test('SodiumException is caught by catch without specified type.', () {
    try {
      throw SodiumException('Terrible things happened.');
    } catch (e) {
      expect(e, isInstanceOf<SodiumException>());
    }
  });
}
