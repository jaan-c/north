import 'dart:io';

import 'package:flutter/foundation.dart';

import 'media_metadata.dart';
import 'media_metadata_store.dart';
import 'media_store.dart';
import 'thumbnail_store.dart';

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

  Future<void> clearMediaCache() async {
    await _mediaStore.clearCache();
  }

  Future<void> clearThumbnailCache() async {
    await _thumbnailStore.clearCache();
  }

  Future<void> dispose() async {
    await _metadataStore.dispose();
    await clearMediaCache();
    await clearThumbnailCache();
  }
}
