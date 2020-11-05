import 'dart:io';

import 'package:flutter/foundation.dart';

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
  final File thumbnail;

  Album({@required this.name, @required this.thumbnail});
}

class Media {
  final Uuid id;
  final String name;
  final DateTime storeDateTime;
  final MediaType type;
  final File thumbnail;

  Media(
      {@required this.id,
      @required this.name,
      @required this.storeDateTime,
      @required this.type,
      @required this.thumbnail});
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
      {@required String password,
      bool shouldPersistMetadata = true,
      Directory externalRoot,
      Directory cacheRoot})
      : _metadataStore =
            MediaMetadataStore(shouldPersist: shouldPersistMetadata),
        _mediaStore =
            MediaStore(password: password, externalRoot: externalRoot),
        _thumbnailStore =
            ThumbnailStore(password: password, cacheRoot: cacheRoot);

  /// Get all [Album]s ordered alphabetically.
  ///
  /// This will create a cache of decrypted thumbnails for the returned albums.
  Future<List<Album>> getAllAlbums() async {
    final albums = <Album>[];
    for (final albumName in await _metadataStore.getAlbumNames()) {
      final thumbnail = await _getThumbnailOfAlbum(albumName);
      final album = Album(name: albumName, thumbnail: thumbnail);

      albums.add(album);
    }

    return albums;
  }

  Future<File> _getThumbnailOfAlbum(String name) async {
    final newestMeta = await _getNewestMetaOfAlbum(name);
    return _thumbnailStore.get(newestMeta.id, newestMeta.salt);
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
      final thumbnail = await _thumbnailStore.get(meta.id, meta.salt);
      final media = Media(
          id: meta.id,
          name: meta.name,
          storeDateTime: meta.storeDateTime,
          type: meta.type,
          thumbnail: thumbnail);

      medias.add(media);
    }

    return medias;
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
