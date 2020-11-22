import 'package:flutter_test/flutter_test.dart';
import 'package:north/private_gallery.dart';
import 'package:north/src/private_gallery/media_metadata.dart';
import 'package:north/src/private_gallery/media_metadata_store.dart';

void main() {
    MediaMetadataStore store;
    MediaMetadata metadata;

    setUp(() {
      store = MediaMetadataStore(shouldPersist: false);
      metadata = MediaMetadata(
          id: Uuid.generate(),
          album: 'Test Album',
          name: 'Test Media',
          storeDateTime: DateTime(2020, 12, 25),
          type: MediaType.image);
    });

    tearDown(() async {
      await store.dispose();
    });

    test('put throws on existing id.', () async {
      await expectLater(store.put(metadata), completes);
      await expectLater(store.put(metadata),
          throwsA(isInstanceOf<MediaMetadataStoreException>()));
    });

    test('get throws on non-existing id.', () async {
      final nonExistingId = Uuid.generate();

      await store.put(metadata);

      await expectLater(store.get(metadata.id), completion(metadata));
      await expectLater(store.get(nonExistingId),
          throwsA(isInstanceOf<MediaMetadataStoreException>()));
    });
}
