import 'package:flutter_test/flutter_test.dart';
import 'package:north/private_gallery.dart';
import 'package:north/src/private_gallery/media_metadata.dart';

void main() {
  test('== implements proper structural equality.', () {
    final id = Uuid.generate();
    final m1 = MediaMetadata(
        id: id,
        album: 'Test Album',
        name: 'Test Media',
        storeDateTime: DateTime(2020, 12, 25));
    final m2 = MediaMetadata(
        id: id,
        album: 'Test Album',
        name: 'Test Media',
        storeDateTime: DateTime(2020, 12, 25));
    final m3 = MediaMetadata(
        id: Uuid.generate(),
        album: 'Test Album',
        name: 'Test Media',
        storeDateTime: DateTime(2021, 1, 1));

    expect(m1, m2);
    expect(m1, isNot(equals(m3)));
  });
}
