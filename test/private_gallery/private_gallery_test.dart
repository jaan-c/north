import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:north/crypto.dart';
import 'package:north/private_gallery.dart';
import 'package:path/path.dart' as pathlib;

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
        gallery.getMediasOfAlbum('Album'), throwsPrivateGalleryException);
  });

  test('put places media under app root.', () async {
    final id = Uuid.generate();
    final media = tempDir.file();
    await media.writeAsBytes(randomBytes(1024));

    await gallery.put(id, 'Album', media);

    final descendants = await tempAppRoot.list(recursive: true).toList();
    final encryptedFile =
        descendants.firstWhere((e) => pathlib.basename(e.path) == id.asString);
    await expectLater(encryptedFile, isInstanceOf<File>());
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
    expect(albums.map((a) => a.mediaCount).toList(), equals([1, 1, 1]));
  });

  test('getMediasOfAlbum throws ArgumentError on empty name.', () async {
    await expectLater(gallery.getMediasOfAlbum(''), throwsArgumentError);
  });

  test('getMediasOfAlbum throws PrivateGalleryException on non-existent album.',
      () async {
    final media = tempDir.file();
    await media.writeAsBytes(randomBytes(1024));

    await gallery.put(Uuid.generate(), 'Album', media);

    await expectLater(gallery.getMediasOfAlbum('Non Existent'),
        throwsPrivateGalleryException);
  });

  test(
      'getMediasOfAlbum only retrieves media inside passed album sorted by comparator.',
      () async {
    final media = tempDir.file();
    await media.writeAsBytes(randomBytes(1024));

    final firstId = Uuid.generate();
    final secondId = Uuid.generate();
    final thirdId = Uuid.generate();
    await gallery.put(firstId, 'A', media);
    await gallery.put(secondId, 'A', media);
    await gallery.put(thirdId, 'A', media);
    await gallery.put(Uuid.generate(), 'B', media);
    await gallery.put(Uuid.generate(), 'B', media);

    final medias = await gallery.getMediasOfAlbum('A');
    expect(
        medias.map((m) => m.id).toList(), equals([thirdId, secondId, firstId]));
  });

  test('loadAlbumThumbnail throws ArgumentError on empty name.', () async {
    await expectLater(gallery.loadAlbumThumbnail(''), throwsArgumentError);
  });

  test(
      'loadAlbumThumbnail throws PrivateGalleryException on non-existent album.',
      () async {
    await expectLater(gallery.loadAlbumThumbnail('NonExistent'),
        throwsPrivateGalleryException);
  });

  test('loadAlbumThumbnail returns a file under cache root.', () async {
    final media = tempDir.file();
    await media.writeAsBytes(randomBytes(1024));

    await gallery.put(Uuid.generate(), 'Album', media);

    final thumbnail = await gallery.loadAlbumThumbnail('Album');
    await expectLater(
        pathlib.isWithin(tempCacheRoot.path, thumbnail.path), isTrue);
  });

  test('loadMediaThumbnail throws PrivateGalleryException on non-existent id.',
      () async {
    await expectLater(gallery.loadMediaThumbnail(Uuid.generate()),
        throwsPrivateGalleryException);
  });

  test('loadMediaThumbnail returns a file under cache root.', () async {
    final media = tempDir.file();
    await media.writeAsBytes(randomBytes(1024));
    final id = Uuid.generate();

    await gallery.put(id, 'Album', media);

    final thumbnail = await gallery.loadMediaThumbnail(id);
    await expectLater(
        pathlib.isWithin(tempCacheRoot.path, thumbnail.path), isTrue);
  });

  test('loadMedia throws PrivateGalleryException on non-existent id.',
      () async {
    await expectLater(
        gallery.loadMedia(Uuid.generate()), throwsPrivateGalleryException);
  });

  test('loadMedia returns a file under cache root.', () async {
    final media = tempDir.file();
    await media.writeAsBytes(randomBytes(1024));
    final id = Uuid.generate();

    await gallery.put(id, 'Album', media);

    final cachedMedia = await gallery.loadMedia(id);
    await expectLater(
        pathlib.isWithin(tempCacheRoot.path, cachedMedia.path), isTrue);
  });
}
