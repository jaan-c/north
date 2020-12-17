import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';
import 'package:quiver/check.dart';
import 'package:quiver/core.dart';

import 'cancellable_future.dart';
import 'media_metadata.dart';
import 'media_metadata_store.dart';
import 'media_store.dart';
import 'thumbnail_store.dart';
import 'uuid.dart';
import 'file_system_utils.dart';
import 'thumbnail_generator.dart';

/// Predefined [Comparator]s for [Media].
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

/// An encrypted storage for media files.
class PrivateGallery {
  static const _mediaDirName = 'medias';
  static const _thumbnailDirName = 'thumbnails';
  static const _mediaCacheDirName = 'media_cache';
  static const _thumbnailCacheDirName = 'thumbnail_cache';

  /// Create a new instance of [PrivateGallery].
  ///
  /// [key] is used for encryption and decryption,
  /// [thumbnailGenerator] is called when generating thumbnails for newly stored
  /// media. If [shouldPersistMetadata] is false, metadata is not written to
  /// disk. [appRoot] is where encrypted media and thumbnails are stored.
  /// [cacheRoot] is where temporarily decrypted media and thumbnails are stored
  /// and must be cleaned up by calling [dispose].
  ///
  /// By default [appRoot] is [getExternalStorageDirectory] and [cacheRoot] is
  /// the first output of [getExternalCacheDirectories] that is under
  /// /storage/emulated, to make sure it's the non-removable storage of the
  /// device and not an external memory card.
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
  final List<VoidCallback> _listeners = [];

  var _isDisposed = false;

  PrivateGallery._internal(
      {@required ThumbnailGenerator thumbnailGenerator,
      @required MediaMetadataStore metadataStore,
      @required MediaStore mediaStore,
      @required ThumbnailStore thumbnailStore})
      : _thumbnailGenerator = thumbnailGenerator,
        _metadataStore = metadataStore,
        _mediaStore = mediaStore,
        _thumbnailStore = thumbnailStore;

  bool hasListener(VoidCallback listener) {
    return _listeners.contains(listener);
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _callListeners() {
    _listeners.forEach((l) => l());
  }

  /// Store [media] inside album named [albumName].
  ///
  /// If the album does not exist, it is created.
  ///
  /// Throws [ArgumentError] if album is empty. Throws [CancelledException] if
  /// [CancellableFuture.cancel] is called.
  CancellableFuture<void> put(Uuid id, String albumName, File media) {
    return CancellableFuture(
        (state) => _putInStores(id, albumName, media, state));
  }

  Future<void> _putInStores(
      Uuid id, String albumName, File media, CancelState state) async {
    _checkIsDisposed();
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

      _callListeners();
    } catch (e) {
      await _metadataStore.delete(id);
      await _thumbnailStore.delete(id);
      await _mediaStore.delete(id);
      rethrow;
    }
  }

  /// Copy [id] content to [duplicateId] placed inside [album].
  ///
  /// If [album] does not exist, it is created.
  ///
  /// Throws [ArgumentError] if [album] is empty. Throws
  /// [PrivateGallerException] if media with [id] does not exist or if
  /// media with [duplicateId] already exists.
  CancellableFuture<void> copyMedia(Uuid id, String album, Uuid duplicateId) {
    return CancellableFuture(
        (state) => _copyStoreEntries(id, album, duplicateId, state));
  }

  Future<void> _copyStoreEntries(
      Uuid id, String album, Uuid duplicateId, CancelState state) async {
    checkArgument(album.isNotEmpty, message: 'album is empty');

    if (!await _metadataStore.has(id)) {
      throw PrivateGalleryException('Media $id does not exist.');
    } else if (await _metadataStore.has(duplicateId)) {
      throw PrivateGalleryException('Media $duplicateId already exists.');
    }

    try {
      state.checkIsCancelled();

      final meta = await _metadataStore.get(id);
      final duplicateMeta = meta.copy(id: duplicateId, album: album);
      await _metadataStore.put(duplicateMeta);

      await _thumbnailStore.duplicate(id, duplicateId).rebindState(state);

      await _mediaStore.duplicate(id, duplicateId).rebindState(state);

      _callListeners();
    } catch (e) {
      await _metadataStore.delete(duplicateId);
      await _thumbnailStore.delete(duplicateId);
      await _mediaStore.delete(duplicateId);
      rethrow;
    }
  }

  /// Get all [Album]s ordered alphabetically.
  Future<List<Album>> getAllAlbums() async {
    _checkIsDisposed();

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
  /// Throws [ArgumentError] if [name] is empty. Throws
  /// [PrivateGalleryException] if album with [name] does not exist.
  Future<List<Media>> getAlbumMedias(String name,
      {Comparator<Media> comparator = MediaOrder.newest}) async {
    _checkIsDisposed();
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
  ///
  /// There is no guarantee that the returned [File] will be kept, so every
  /// access to the album thumbnail must call this method.
  ///
  /// Throws [ArgumentError] if [name] is empty. Throws
  /// [PrivateGalleryException] if album with [name] does not exist.
  Future<File> loadAlbumThumbnail(String name) async {
    _checkIsDisposed();
    checkArgument(name.isNotEmpty, message: 'name is empty.');

    final newestMedia =
        (await getAlbumMedias(name, comparator: MediaOrder.newest)).first;
    return _thumbnailStore.get(newestMedia.id);
  }

  /// Return the decrypted thumbnail of media with [id] as a cached [File].
  ///
  /// There is no guarantee that the returned [File] will be kept, so every
  /// access to the media thumbnail must call this method.
  ///
  /// Throws [PrivateGalleryException] if [id] does not exist.
  Future<File> loadMediaThumbnail(Uuid id) async {
    _checkIsDisposed();

    if (!await _metadataStore.has(id)) {
      throw PrivateGalleryException('Media $id does not exist.');
    }

    return _thumbnailStore.get(id);
  }

  /// Return the decrypted media with [id] as cached [File].
  ///
  /// There is no guarantee that the returned [File] will be kept, so every
  /// access to the media must call this method.
  ///
  /// Throws [PrivateGalleryException] if [id] does not exist.
  CancellableFuture<File> loadMedia(Uuid id) {
    _checkIsDisposed();

    return CancellableFuture((state) async {
      if (!await _metadataStore.has(id)) {
        throw PrivateGalleryException('Media $id does not exist.');
      }

      return _mediaStore.get(id).rebindState(state);
    });
  }

  /// Delete media with [id].
  ///
  /// Noop if [id] does not exist. If the album where the media is in is the
  /// only item, the album is also deleted.
  Future<void> delete(Uuid id) async {
    _checkIsDisposed();

    final metaResult = _metadataStore.delete(id);
    final thumbnailResult = _thumbnailStore.delete(id);
    final mediaResult = _mediaStore.delete(id);

    await Future.wait([metaResult, thumbnailResult, mediaResult],
        eagerError: true);

    _callListeners();
  }

  /// Rename album with [oldName] to [newName].
  ///
  /// Throws [ArgumentError] if [oldName] or [newName] is empty or if there is
  /// no album named [oldName]. Throws [PrivateGalleryException] if album named
  /// [oldName] does not exist or if renaming to an already existing album named
  /// [newName].
  Future<void> renameAlbum(String oldName, String newName) async {
    _checkIsDisposed();
    checkArgument(oldName.isNotEmpty, message: 'oldName is empty.');
    checkArgument(newName.isNotEmpty, message: 'newName is empty.');

    final allAlbums = await _metadataStore.getAlbumNames();
    if (!allAlbums.contains(oldName)) {
      throw PrivateGalleryException('Renaming a non-existent album $oldName.');
    } else if (allAlbums.contains(newName)) {
      throw PrivateGalleryException(
          'Renaming album $oldName to an already existing album $newName.');
    } else if (oldName == newName) {
      return;
    }

    final oldMetas = await _metadataStore.getByAlbum(oldName);
    final newMetas = oldMetas.map((m) => m.copy(album: newName)).toList();

    await _metadataStore.update(newMetas);

    _callListeners();
  }

  /// Rename media with [id] to [newName].
  ///
  /// Throws [ArgumentError] if [newName] is empty or or there is no media with
  /// [id].
  Future<void> renameMedia(Uuid id, String newName) async {
    _checkIsDisposed();
    checkArgument(newName.isNotEmpty, message: 'newName is empty');

    MediaMetadata oldMeta;
    try {
      oldMeta = await _metadataStore.get(id);
    } on MediaMetadataStoreException catch (_) {
      throw PrivateGalleryException('Renaming a non-existent media $id.');
    }
    final newMeta = oldMeta.copy(name: newName);

    if (oldMeta.name == newMeta.name) {
      return;
    } else {
      await _metadataStore.update([newMeta]);
      _callListeners();
    }
  }

  /// Move media with [id] to [destinationAlbum].
  ///
  /// Throws [ArgumentError] if [destinationAlbum] is empty. Throws
  /// [PrivateGalleryException] if either [id] or [destinationAlbum] does not
  /// exist.
  Future<void> moveMediaToAlbum(Uuid id, String destinationAlbum) async {
    _checkIsDisposed();
    checkArgument(destinationAlbum.isNotEmpty,
        message: 'destinationAlbum is empty');

    final allAlbums = await _metadataStore.getAlbumNames();
    if (!await allAlbums.contains(destinationAlbum)) {
      throw PrivateGalleryException(
          'Moving media $id to non-existent destination album $destinationAlbum.');
    }

    MediaMetadata oldMeta;
    try {
      oldMeta = await _metadataStore.get(id);
    } on MediaMetadataStoreException catch (_) {
      throw PrivateGalleryException(
          'Moving a non-existent media $id to album $destinationAlbum.');
    }
    final newMeta = oldMeta.copy(album: destinationAlbum);

    if (oldMeta.album == destinationAlbum) {
      return;
    } else {
      await _metadataStore.update([newMeta]);
      _callListeners();
    }
  }

  void _checkIsDisposed() {
    if (_isDisposed) {
      throw PrivateGalleryException('This instance is already disposed.');
    }
  }

  /// Dispose this object and all caches.
  Future<void> dispose() async {
    if (!_isDisposed) {
      await _metadataStore.dispose();
      await _mediaStore.clearCache();
      await _thumbnailStore.clearCache();
      _listeners.clear();

      _isDisposed = true;
    }
  }
}
