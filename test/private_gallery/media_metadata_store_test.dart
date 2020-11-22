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

  test('renameAlbum renames all media with old album to new.', () async {
    final oldAlbum = 'Photos';
    final newAlbum = 'Pictures';
    final oldMeta1 = MediaMetadata(
        id: Uuid.generate(),
        album: oldAlbum,
        name: 'Picture 1',
        storeDateTime: DateTime.now(),
        type: MediaType.image);
    final oldMeta2 = MediaMetadata(
        id: Uuid.generate(),
        album: oldAlbum,
        name: 'Picture 2',
        storeDateTime: DateTime.now(),
        type: MediaType.video);
    final oldMeta3 = MediaMetadata(
        id: Uuid.generate(),
        album: 'Static',
        name: 'Picture 3',
        storeDateTime: DateTime.now(),
        type: MediaType.image);

    final newMeta1 = MediaMetadata(
        id: oldMeta1.id,
        album: newAlbum,
        name: oldMeta1.name,
        storeDateTime: oldMeta1.storeDateTime,
        type: oldMeta1.type);
    final newMeta2 = MediaMetadata(
        id: oldMeta2.id,
        album: newAlbum,
        name: oldMeta2.name,
        storeDateTime: oldMeta2.storeDateTime,
        type: oldMeta2.type);

    await store.put(oldMeta1);
    await store.put(oldMeta2);
    await store.put(oldMeta3);

    await store.renameAlbum(oldAlbum, newAlbum);

    await expectLater(store.get(oldMeta1.id), completion(newMeta1));
    await expectLater(store.get(oldMeta2.id), completion(newMeta2));
    await expectLater(store.get(oldMeta3.id), completion(oldMeta3));
  });
}
