import 'package:flutter_test/flutter_test.dart';
import 'package:north/private_gallery.dart';

void main() {
  test('fromString rejects non-hex, non 32 length strings.', () {
    final shortHex = '123abc';
    final nonHex = 'TheQuickBrownFoxJumpsOverTheLazy'; // 32 length.
    final validHex = '123e4567e89b12d3a456426614174000';

    expect(() => Uuid(shortHex), throwsAssertionError);
    expect(() => Uuid(nonHex), throwsAssertionError);
    expect(() => Uuid(validHex), returnsNormally);
  });

  test('toString returns a string with 32 length lowercased hex.', () {
    final uuid = Uuid.generate();
    final hex = RegExp(r'^[0-9a-f]+$', caseSensitive: false);

    expect(uuid.asString, hasLength(32));
    expect(uuid.asString, matches(hex));
    expect(uuid.asString, equals(uuid.asString.toLowerCase()));
  });

  test('constructor and asString are inverse.', () {
    final uuid1 = Uuid.generate();
    final uuid2 = Uuid(uuid1.asString);

    expect(uuid1, uuid2);
  });

  test('== rejects input String with the same Uuid.asString value.', () {
    final uuid = Uuid.generate();

    expect(uuid, isNot(equals(uuid.asString)));
  });
}
