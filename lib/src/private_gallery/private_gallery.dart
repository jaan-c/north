import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:north/src/private_gallery/thumbnail_generator.dart';
import 'package:path/path.dart' as pathlib;
import 'package:quiver/check.dart';

import 'cancelable_future.dart';
import 'loader.dart';
import 'media_metadata.dart';
import 'media_metadata_store.dart';
import 'media_store.dart';
import 'thumbnail_store.dart';
import 'uuid.dart';

enum MediaOrder { nameAscending, nameDescending, newest, oldest }

extension _MediaOrderAsComparator on MediaOrder {
  Comparator<MediaMetadata> get asComparator {
    switch (this) {
      case MediaOrder.nameAscending:
        return (a, b) => a.name.compareTo(b.name);
      case MediaOrder.nameDescending:
        return (a, b) => b.name.compareTo(a.name);
      case MediaOrder.newest:
        return (a, b) => b.storeDateTime.compareTo(a.storeDateTime);
      case MediaOrder.oldest:
        return (a, b) => a.storeDateTime.compareTo(b.storeDateTime);
      default:
        throw StateError('Unhandled $this');
    }
  }
}

class Album {
  final String name;
  final ThumbnailLoader thumbnailLoader;

  Album({@required this.name, @required this.thumbnailLoader});
}

class Media {
  final Uuid id;
  final String name;
  final DateTime storeDateTime;
  final MediaType type;
  final ThumbnailLoader thumbnailLoader;
  final MediaLoader mediaLoader;

  Media(
      {@required this.id,
      @required this.name,
      @required this.storeDateTime,
      @required this.type,
      @required this.thumbnailLoader,
      @required this.mediaLoader});
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
  final ThumbnailGenerator thumbnailGenerator;
  final MediaMetadataStore _metadataStore;
  final MediaStore _mediaStore;
  final ThumbnailStore _thumbnailStore;

  PrivateGallery(Uint8List key,
      {this.thumbnailGenerator = generateThumbnail,
      bool shouldPersistMetadata = true,
      Directory externalRoot,
      Directory cacheRoot})
      : _metadataStore =
            MediaMetadataStore(shouldPersist: shouldPersistMetadata),
        _mediaStore = MediaStore(key: key, externalRoot: externalRoot),
        _thumbnailStore = ThumbnailStore(key: key, cacheRoot: cacheRoot);

  /// Store [media] inside [album].
  ///
  /// Throws [PrivateGalleryException] if there is already a media with [id] or
  /// [media] is neither an image or a video.
  ///
  /// Throws [CancelledException] if [CancelableFuture.cancel] is called.
  CancelableFuture<void> put(Uuid id, String album, File media) {
    return CancelableFuture((state) => _putInStores(id, album, media, state));
  }

  Future<void> _putInStores(
      Uuid id, String album, File media, CancelState state) async {
    try {
      state.checkIsCancelled();

      final meta = MediaMetadata(
          id: id,
          album: album,
          name: pathlib.basename(media.path),
          storeDateTime: DateTime.now(),
          type: await _getMediaType(media));
      await _metadataStore.put(meta);

      state.checkIsCancelled();

      final thumbnailBytes = await thumbnailGenerator(media);
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
      final thumbnailLoader = await _getThumbnailLoaderOfAlbum(albumName);
      final album = Album(name: albumName, thumbnailLoader: thumbnailLoader);

      albums.add(album);
    }

    return albums;
  }

  Future<ThumbnailLoader> _getThumbnailLoaderOfAlbum(String name) async {
    final newestMeta = await _getNewestMetaOfAlbum(name);
    return ThumbnailLoader(newestMeta.id, _thumbnailStore);
  }

  Future<MediaMetadata> _getNewestMetaOfAlbum(String name) async {
    final all = await _metadataStore.getByAlbum(name,
        sortBy: MediaOrder.newest.asComparator);
    return all.first;
  }

  /// Get [Media]s of album sorted by [orderBy].
  ///
  /// This will create a cache of decrypted thumbnails for the returned medias.
  ///
  /// Throws [ArgumentError] if [name] is empty or there is no album with
  /// [name].
  Future<List<Media>> getMediasInAlbum(String name,
      {MediaOrder orderBy = MediaOrder.newest}) async {
    checkArgument(name.isNotEmpty, message: 'name is empty.');

    final metas =
        await _metadataStore.getByAlbum(name, sortBy: orderBy.asComparator);

    checkArgument(metas.isNotEmpty, message: 'Album "$name" does not exist.');

    final medias = <Media>[];
    for (final meta in metas) {
      final thumbnailLoader = ThumbnailLoader(meta.id, _thumbnailStore);
      final mediaLoader = MediaLoader(meta.id, _mediaStore);
      final media = Media(
          id: meta.id,
          name: meta.name,
          storeDateTime: meta.storeDateTime,
          type: meta.type,
          thumbnailLoader: thumbnailLoader,
          mediaLoader: mediaLoader);

      medias.add(media);
    }

    return medias;
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

  /// Clear all media cache. This is also called by [dispose].
  Future<void> clearMediaCache() async {
    await _mediaStore.clearCache();
  }

  /// Clear all thumbnail cache. This is also called by [dispose].
  Future<void> clearThumbnailCache() async {
    await _thumbnailStore.clearCache();
  }

  /// Dispose of this object and all caches.
  Future<void> dispose() async {
    await _metadataStore.dispose();
    await clearMediaCache();
    await clearThumbnailCache();
  }
}

Future<MediaType> _getMediaType(File media) async {
  final header = await _readMediaHeader(media);
  final mime = lookupMimeType(media.path, headerBytes: header);
  if (mime.startsWith('image')) {
    return MediaType.image;
  } else if (mime.startsWith('video')) {
    return MediaType.video;
  } else {
    throw PrivateGalleryException(
        '${media.path} is neither an image or a video.');
  }
}

Future<List<int>> _readMediaHeader(File media) async {
  final ram = await media.open();
  try {
    final header = await ram.read(defaultMagicNumbersMaxLength);
    return header;
  } finally {
    await ram.close();
  }
}
