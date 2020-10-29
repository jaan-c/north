import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:north/src/private_gallery/commons.dart';
import 'package:north/src/private_gallery/media_metadata_store/media_metadata.dart';
import 'package:north/src/private_gallery/media_metadata_store/media_metadata_store.dart';

import '../../utils.dart';

void main() {
  group('MediaMetadata', () {
    test('== implements proper structural equality.', () {
      final salt = randomBytes(16);
      final m1 = MediaMetadata(
          album: 'Test Album',
          name: 'Test Media',
          salt: salt,
          storeDateTime: DateTime(2020, 12, 25),
          type: MediaType.image);
      final m2 = MediaMetadata(
          album: 'Test Album',
          name: 'Test Media',
          salt: salt,
          storeDateTime: DateTime(2020, 12, 25),
          type: MediaType.image);
      final m3 = MediaMetadata(
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
    MediaMetadataStore store;
    MediaMetadata metadata;

    setUp(() {
      store = MediaMetadataStore();
      metadata = MediaMetadata(
          album: 'Test Album',
          name: 'Test Media',
          salt: randomBytes(16),
          storeDateTime: DateTime(2020, 12, 25),
          type: MediaType.image);
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      store = null;
      metadata = null;
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
