import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:north/crypto.dart';
import 'package:north/private_gallery.dart';

import '../utils.dart';

void main() {
  final throwsPrivateGalleryException =
      throwsA(isInstanceOf<PrivateGalleryException>());
  final throwsCancelledException = throwsA(isInstanceOf<CancelledException>());

  final dummyThumbnailContent = randomBytes(1024);
  final dummyThumbnailGenerator = (File _) async => dummyThumbnailContent;

  Directory tempAppRoot;
  Directory tempCacheRoot;
  PrivateGallery gallery;
  Directory tempDir;

  setUp(() async {
    tempAppRoot = await createTempDir('app_root');
    tempCacheRoot = await createTempDir('cache_root');
    gallery = await PrivateGallery.instantiate(
        await deriveKey('Password', generateSalt()),
        shouldPersistMetadata: false,
        thumbnailGenerator: dummyThumbnailGenerator,
        appRoot: tempAppRoot,
        cacheRoot: tempCacheRoot);
    tempDir = await createTempDir();
  });

  tearDown(() async {
    await gallery.dispose();
    await tempAppRoot.delete(recursive: true);
    await tempCacheRoot.delete(recursive: true);
    await tempDir.delete(recursive: true);
  });

  test('put throws ArgumentError on empty album name.', () async {
    final id = Uuid.generate();
    final media = tempDir.file();
    await media.writeAsBytes(randomBytes(1024));

    await expectLater(gallery.put(id, '', media), throwsArgumentError);
  });

  test('put throws PrivateGalleryException on already existing id.', () async {
    final id = Uuid.generate();
    final media = tempDir.file();
    await media.writeAsBytes(randomBytes(1024));

    await expectLater(gallery.put(id, 'Album 1', media), completes);
    await expectLater(
        gallery.put(id, 'Album 2', media), throwsPrivateGalleryException);
  });

  test('put throws CancelledException on cancel.', () async {
    final id = Uuid.generate();
    final media = tempDir.file();
    await media.writeAsBytes(randomBytes(1024));

    final future = gallery.put(id, 'Album', media);
    future.cancel();

    await expectLater(future, throwsCancelledException);
    await expectLater(
        gallery.getMediasInAlbum('Album'), throwsPrivateGalleryException);
  });

  test('getAllAlbums returns an empty list when there are no albums.',
      () async {
    await expectLater(gallery.getAllAlbums(), completion(equals([])));
  });

  test('getAllAlbums retrieves all existing album names alphabetically.',
      () async {
    final media = tempDir.file();
    await media.writeAsBytes(randomBytes(1024));

    await gallery.put(Uuid.generate(), 'B', media);
    await gallery.put(Uuid.generate(), 'C', media);
    await gallery.put(Uuid.generate(), 'A', media);

    final albums = await gallery.getAllAlbums();
    expect(albums.map((a) => a.name).toList(), equals(['A', 'B', 'C']));

    await expectLater(albums[0].thumbnailLoader.loadAsBytes(),
        completion(equals(dummyThumbnailContent)));
    await expectLater(albums[1].thumbnailLoader.loadAsBytes(),
        completion(equals(dummyThumbnailContent)));
    await expectLater(albums[2].thumbnailLoader.loadAsBytes(),
        completion(equals(dummyThumbnailContent)));
  });
}

extension LoadAsBytes on ThumbnailLoader {
  Future<List<int>> loadAsBytes() async {
    final file = await load();
    return file.readAsBytes();
  }
}
