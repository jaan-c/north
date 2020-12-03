import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:north/src/private_gallery/thumbnail_generator.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';
import 'package:quiver/check.dart';
import 'package:quiver/core.dart';

import 'cancelable_future.dart';
import 'media_metadata.dart';
import 'media_metadata_store.dart';
import 'media_store.dart';
import 'thumbnail_store.dart';
import 'uuid.dart';
import 'file_system_utils.dart';

class MediaOrder {
  static int nameAscending(Media a, Media b) {
    return a.name.compareTo(b.name);
  }

  static int nameDescending(Media a, Media b) {
    return b.name.compareTo(a.name);
  }

  static int newest(Media a, Media b) {
    return b.storeDateTime.compareTo(a.storeDateTime);
  }

  static int oldest(Media a, Media b) {
    return a.storeDateTime.compareTo(b.storeDateTime);
  }
}

class Album {
  final String name;
  final int mediaCount;

  Album(this.name, this.mediaCount);

  @override
  bool operator ==(dynamic other) =>
      other is Album && hashCode == other.hashCode;

  @override
  int get hashCode => hash2(name, mediaCount);
}

class Media {
  final Uuid id;
  final String name;
  final DateTime storeDateTime;

  Media(this.id, this.name, this.storeDateTime);

  @override
  bool operator ==(dynamic other) =>
      other is Media && hashCode == other.hashCode;

  @override
  int get hashCode => hash3(id, name, storeDateTime);
}

class PrivateGalleryException implements Exception {
  final String message;
  PrivateGalleryException(this.message);
  @override
  String toString() => '${(PrivateGalleryException)}: $message';
}

typedef ThumbnailGenerator = Future<List<int>> Function(File media);

/// A private encrypted gallery.
///
/// Files are stored encrypted in a .north directory inside [externalRoot].
/// Media and thumbnail on access will be decrypted and cached inside
/// [cacheRoot] with respective directories media_cache and thumbnail_cache;
/// which should be cleared at some point before the program closes.
///
/// By default [externalRoot] is [ExtStorage.getExternalStorageDirectory] and
/// [cacheRoot] is [getExternalCacheDirectories]. If [shouldPersistMetadata] is
/// false, metadata is only stored in memory.
class PrivateGallery {
  static const _mediaDirName = 'medias';
  static const _thumbnailDirName = 'thumbnails';
  static const _mediaCacheDirName = 'media_cache';
  static const _thumbnailCacheDirName = 'thumbnail_cache';

  static Future<PrivateGallery> instantiate(Uint8List key,
      {ThumbnailGenerator thumbnailGenerator = generateThumbnail,
      bool shouldPersistMetadata = true,
      Directory appRoot,
      Directory cacheRoot}) async {
    appRoot ??= await getExternalStorageDirectory();
    cacheRoot ??= (await getExternalCacheDirectories())
        .firstWhere((dir) => pathlib.isWithin('/storage/emulated', dir.path));

    final mediaDir =
        await appRoot.directory(_mediaDirName).create(recursive: true);
    final thumbnailDir =
        await appRoot.directory(_thumbnailDirName).create(recursive: true);
    final mediaCacheDir =
        await cacheRoot.directory(_mediaCacheDirName).create(recursive: true);
    final thumbnailCacheDir = await cacheRoot
        .directory(_thumbnailCacheDirName)
        .create(recursive: true);

    return PrivateGallery._internal(
        thumbnailGenerator: thumbnailGenerator,
        metadataStore: await MediaMetadataStore.instantiate(
            shouldPersist: shouldPersistMetadata),
        mediaStore: await MediaStore(
            key: key, mediaDir: mediaDir, cacheDir: mediaCacheDir),
        thumbnailStore: await ThumbnailStore(
            key: key, thumbnailDir: thumbnailDir, cacheDir: thumbnailCacheDir));
  }

  final ThumbnailGenerator _thumbnailGenerator;
  final MediaMetadataStore _metadataStore;
  final MediaStore _mediaStore;
  final ThumbnailStore _thumbnailStore;

  PrivateGallery._internal(
      {@required ThumbnailGenerator thumbnailGenerator,
      @required MediaMetadataStore metadataStore,
      @required MediaStore mediaStore,
      @required ThumbnailStore thumbnailStore})
      : _thumbnailGenerator = thumbnailGenerator,
        _metadataStore = metadataStore,
        _mediaStore = mediaStore,
        _thumbnailStore = thumbnailStore;

  /// Store [media] inside [albumName].
  ///
  /// Throws [ArgumentError] if album is empty. Throws [PrivateGalleryException]
  /// if there is already a media with [id] or [media] is neither an image or a
  /// video. Throws [CancelledException] if [CancelableFuture.cancel] is called.
  CancelableFuture<void> put(Uuid id, String albumName, File media) {
    return CancelableFuture(
        (state) => _putInStores(id, albumName, media, state));
  }

  Future<void> _putInStores(
      Uuid id, String albumName, File media, CancelState state) async {
    checkArgument(albumName.isNotEmpty, message: 'album is empty.');

    if (await _metadataStore.has(id)) {
      throw PrivateGalleryException('Media $id already exists.');
    }

    try {
      state.checkIsCancelled();

      final meta = MediaMetadata(
          id: id,
          album: albumName,
          name: pathlib.basename(media.path),
          storeDateTime: DateTime.now());
      await _metadataStore.put(meta);

      state.checkIsCancelled();

      final thumbnailBytes = await _thumbnailGenerator(media);
      await _thumbnailStore
          .putStream(id, Stream.fromIterable([thumbnailBytes]))
          .rebindState(state);

      await _mediaStore.put(id, media).rebindState(state);
    } catch (e) {
      await _metadataStore.delete(id);
      await _thumbnailStore.delete(id);
      await _mediaStore.delete(id);
      rethrow;
    }
  }

  /// Get all [Album]s ordered alphabetically.
  ///
  /// This will create a cache of decrypted thumbnails for the returned albums.
  Future<List<Album>> getAllAlbums() async {
    final albums = <Album>[];
    for (final albumName in await _metadataStore.getAlbumNames()) {
      final metas = await _metadataStore.getByAlbum(albumName);
      final album = Album(albumName, metas.length);

      albums.add(album);
    }

    return albums;
  }

  /// Get [Media]s of album ordered by [comparator].
  ///
  /// This will create a cache of decrypted thumbnails for the returned medias.
  ///
  /// Throws [ArgumentError] if [name] is empty. Throws
  /// [PrivateGalleryException] if album with [name] does not exist.
  Future<List<Media>> getMediasOfAlbum(String name,
      {Comparator<Media> comparator = MediaOrder.newest}) async {
    checkArgument(name.isNotEmpty, message: 'name is empty.');

    final metas = await _metadataStore.getByAlbum(name);

    if (metas.isEmpty) {
      throw PrivateGalleryException('Album $name does not exist.');
    } else {
      return metas.map((m) => Media(m.id, m.name, m.storeDateTime)).toList()
        ..sort(comparator);
    }
  }

  /// Return the decrypted thumbnail of album with [name] as a cached [File].
  Future<File> loadAlbumThumbnail(String name) async {
    checkArgument(name.isNotEmpty, message: 'name is empty.');

    final newestMeta = await _getNewestMetaOfAlbum(name);
    return _thumbnailStore.get(newestMeta.id);
  }

  Future<MediaMetadata> _getNewestMetaOfAlbum(String name) async {
    final all = await _metadataStore.getByAlbum(name,
        sortBy: MediaOrder.newest.asComparator);
    return all.first;
  }

  /// Return the decrypted thumbnail of media with [id] as a cached [File].
  Future<File> loadMediaThumbnail(Uuid id) async {
    return _thumbnailStore.get(id);
  }

  /// Return the decrypted media with [id] as cached [File].
  CancelableFuture<File> loadMedia(Uuid id) {
    return _mediaStore.get(id);
  }

  /// Delete media with [id].
  ///
  /// If the album the media is contained in only has this media, it is also
  /// deleted.
  Future<void> delete(Uuid id) async {
    final metaResult = _metadataStore.delete(id);
    final thumbnailResult = _thumbnailStore.delete(id);
    final mediaResult = _mediaStore.delete(id);

    await Future.wait([metaResult, thumbnailResult, mediaResult],
        eagerError: true);
  }

  /// Rename album with [oldName] to [newName].
  ///
  /// Throws [ArgumentError] if [oldName] or [newName] is empty or if there is
  /// no album named [oldName].
  Future<void> renameAlbum(String oldName, String newName) async {
    checkArgument(oldName.isNotEmpty, message: 'oldName is empty.');
    checkArgument(newName.isNotEmpty, message: 'newName is empty.');

    if (oldName == newName) {
      return;
    }

    final oldMetas = await _metadataStore.getByAlbum(oldName);
    final newMetas = oldMetas.map((m) => m.copy(album: newName));

    checkArgument(oldMetas.isNotEmpty, message: 'No album named $oldName.');

    await _metadataStore.update(newMetas);
  }

  /// Rename media with [id] to [newName].
  ///
  /// Throws [ArgumentError] if [newName] is empty or or there is no media with
  /// [id].
  Future<void> renameMedia(Uuid id, String newName) async {
    checkArgument(newName.isNotEmpty, message: 'newName is empty');

    MediaMetadata oldMeta;
    try {
      oldMeta = await _metadataStore.get(id);
    } on MediaMetadataStoreException catch (_) {
      throw ArgumentError('No media with id $id.');
    }
    final newMeta = oldMeta.copy(name: newName);

    if (oldMeta.name == newMeta.name) {
      return;
    }

    await _metadataStore.update([newMeta]);
  }

  /// Move media with [id] to [destinationAlbum].
  ///
  /// Throws [ArgumentError] if [destinationAlbum] is empty or there is no media
  /// with [id].
  Future<void> moveMediaToAlbum(Uuid id, String destinationAlbum) async {
    checkArgument(destinationAlbum.isNotEmpty,
        message: 'destinationAlbum is empty');

    MediaMetadata oldMeta;
    try {
      oldMeta = await _metadataStore.get(id);
    } on MediaMetadataStoreException catch (_) {
      throw ArgumentError('No media with id $id.');
    }
    final newMeta = oldMeta.copy(album: destinationAlbum);

    if (oldMeta.album == destinationAlbum) {
      return;
    }

    await _metadataStore.update([newMeta]);
  }

  /// Dispose of this object and all caches.
  Future<void> dispose() async {
    await _metadataStore.dispose();
    await _mediaStore.clearCache();
    await _thumbnailStore.clearCache();
  }
}
