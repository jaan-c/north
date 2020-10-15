import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:north/src/private_gallery/commons.dart';
import 'package:north/src/private_gallery/media_metadata_store/media_metadata.dart';
import 'package:north/src/private_gallery/media_metadata_store/media_metadata_store.dart';

void main() {
  group("MediaMetadata", () {
    test("== implements proper structural equality.", () {
      final m1 = MediaMetadata(
          album: "Test Album",
          name: "Test Media",
          salt: "Very salty!",
          storeDateTime: DateTime(2020, 12, 25),
          type: MediaType.image);
      final m2 = MediaMetadata(
          album: "Test Album",
          name: "Test Media",
          salt: "Very salty!",
          storeDateTime: DateTime(2020, 12, 25),
          type: MediaType.image);
      final m3 = MediaMetadata(
          album: "Test Album",
          name: "Test Media",
          salt: "Not salty!",
          storeDateTime: DateTime(2020, 12, 25),
          type: MediaType.image);

      expect(m1, m2);
      expect(m1, isNot(equals(m3)));
    });
  });

  group("MediaMetadataStore", () {
    MediaMetadataStore store;
    MediaMetadata metadata;

    setUp(() async {
      store = await MediaMetadataStore.init();
      metadata = MediaMetadata(
          album: "Test Album",
          name: "Test Media",
          salt: "Very salty!",
          storeDateTime: DateTime(2020, 12, 25),
          type: MediaType.image);
    });

    tearDown(() async {
      await Hive.deleteFromDisk();
      store = null;
      metadata = null;
    });

    test("store throws on existing id.", () async {
      final id = Uuid.generate();

      await expectLater(store.store(id, metadata), completes);
      await expectLater(store.store(id, metadata),
          throwsA(isInstanceOf<MediaMetadataStoreException>()));
    });

    test("query throws on non-existing id.", () async {
      final id = Uuid.generate();
      final nonExistingId = Uuid.generate();

      await store.store(id, metadata);

      await expectLater(store.query(id), completion(metadata));
      await expectLater(store.query(nonExistingId),
          throwsA(isInstanceOf<MediaMetadataStoreException>()));
    });

    test("delete throws on non-existing id.", () async {
      final id = Uuid.generate();

      await store.store(id, metadata);

      await expectLater(store.delete(id), completes);
      await expectLater(store.delete(id),
          throwsA(isInstanceOf<MediaMetadataStoreException>()));
    });
  });
}
