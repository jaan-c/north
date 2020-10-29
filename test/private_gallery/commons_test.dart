import 'package:flutter_test/flutter_test.dart';
import 'package:north/src/private_gallery/commons.dart';

void main() {
  group('Uuid', () {
    test('fromString rejects non-hex, non 32 length strings.', () {
      final shortHex = '123abc';
      final nonHex = 'TheQuickBrownFoxJumpsOverTheLazy'; // 32 length.
      final validHex = '123e4567e89b12d3a456426614174000';

      expect(() => Uuid.fromString(shortHex), throwsStateError);
      expect(() => Uuid.fromString(nonHex), throwsStateError);
      expect(() => Uuid.fromString(validHex), returnsNormally);
    });

    test('toString returns a string with 32 length lowercased hex.', () {
      final uuid = Uuid.generate();
      final hex = RegExp(r'^[0-9a-f]+$', caseSensitive: false);

      expect(uuid.toString(), hasLength(32));
      expect(uuid.toString(), matches(hex));
      expect(uuid.toString(), equals(uuid.toString().toLowerCase()));
    });

    test('fromString and toString are inverse.', () {
      final uuid1 = Uuid.generate();
      final uuid2 = Uuid.fromString(uuid1.toString());

      expect(uuid1, uuid2);
    });

    test('== rejects input String with the same Uuid.toString value.', () {
      final uuid = Uuid.generate();

      expect(uuid, isNot(equals(uuid.toString())));
    });
  });
}
