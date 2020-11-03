import 'package:flutter_test/flutter_test.dart';
import 'package:north/private_gallery.dart';

import '../utils.dart';

void main() {
  group('MediaMetadata', () {
    test('== implements proper structural equality.', () {
      final id = Uuid.generate();
      final salt = randomBytes(16);
      final m1 = MediaMetadata(
          id: id,
          album: 'Test Album',
          name: 'Test Media',
          salt: salt,
          storeDateTime: DateTime(2020, 12, 25),
          type: MediaType.image);
      final m2 = MediaMetadata(
          id: id,
          album: 'Test Album',
          name: 'Test Media',
          salt: salt,
          storeDateTime: DateTime(2020, 12, 25),
          type: MediaType.image);
      final m3 = MediaMetadata(
          id: Uuid.generate(),
          album: 'Test Album',
          name: 'Test Media',
          salt: randomBytes(16),
          storeDateTime: DateTime(2020, 12, 25),
          type: MediaType.image);

      expect(m1, m2);
      expect(m1, isNot(equals(m3)));
    });
  });

  group('MediaMetadataStore', () {
    final metadata = MediaMetadata(
        id: Uuid.generate(),
        album: 'Test Album',
        name: 'Test Media',
        salt: randomBytes(16),
        storeDateTime: DateTime(2020, 12, 25),
        type: MediaType.image);

    MediaMetadataStore store;

    setUp(() {
      store = MediaMetadataStore(shouldPersist: false);
    });

    tearDown(() async {
      await store.dispose();
    });

    test('put throws on existing id.', () async {
      final id = Uuid.generate();

      await expectLater(store.put(id, metadata), completes);
      await expectLater(store.put(id, metadata),
          throwsA(isInstanceOf<MediaMetadataStoreException>()));
    });

    test('get throws on non-existing id.', () async {
      final id = Uuid.generate();
      final nonExistingId = Uuid.generate();

      await store.put(id, metadata);

      await expectLater(store.get(id), completion(metadata));
      await expectLater(store.get(nonExistingId),
          throwsA(isInstanceOf<MediaMetadataStoreException>()));
    });

    test('delete throws on non-existing id.', () async {
      final id = Uuid.generate();

      await store.put(id, metadata);

      await expectLater(store.delete(id), completes);
      await expectLater(store.delete(id),
          throwsA(isInstanceOf<MediaMetadataStoreException>()));
    });
  });
}
