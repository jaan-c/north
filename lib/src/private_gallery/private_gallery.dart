import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

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

/// A private encrypted gallery.
///
/// Files are stored encrypted in a .north directory inside [externalRoot].
/// Media and thumbnail on access will be decrypted and cached inside
/// [cacheRoot] with respective directories media_cache and thumbnail_cache;
/// which should be cleared at some point before the program closes.
class PrivateGallery {
  final MediaMetadataStore _metadataStore;
  final MediaStore _mediaStore;
  final ThumbnailStore _thumbnailStore;

  PrivateGallery(
      {@required Uint8List key,
      bool shouldPersistMetadata = true,
      Directory externalRoot,
      Directory cacheRoot})
      : _metadataStore =
            MediaMetadataStore(shouldPersist: shouldPersistMetadata),
        _mediaStore = MediaStore(key: key, externalRoot: externalRoot),
        _thumbnailStore = ThumbnailStore(key: key, cacheRoot: cacheRoot);

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
  Future<List<Media>> getMediasInAlbum(String name,
      {MediaOrder orderBy = MediaOrder.newest}) async {
    final metas =
        await _metadataStore.getByAlbum(name, sortBy: orderBy.asComparator);
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

  /// Get media with [id].
  ///
  /// This will create a cache of the full decrypted media returned.
  Future<File> getMedia(Uuid id) async {
    return _mediaStore.get(id);
  }

  /// Delete media with [id].
  Future<void> delete(Uuid id) async {
    final metaResult = _metadataStore.delete(id);
    final thumbnailResult = _thumbnailStore.delete(id);
    final mediaResult = _mediaStore.delete(id);

    await Future.wait([metaResult, thumbnailResult, mediaResult],
        eagerError: true);
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
