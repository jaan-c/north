import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:north/private_gallery.dart';

enum MediaOperation { delete, copy, move }

class MediaOperationStatus {
  final double progress;
  final MediaOperation operation;

  MediaOperationStatus({@required this.progress, @required this.operation});
}

class GalleryModel with ChangeNotifier {
  static Future<GalleryModel> instantiate(Uint8List key) async {
    final gallery = await PrivateGallery.instantiate(key);
    return GalleryModel._internal(gallery);
  }

  final PrivateGallery _gallery;

  Album get openedAlbum => _openedAlbum;
  Media get openedMedia => _openedMedia;

  Album _openedAlbum;
  Media _openedMedia;

  GalleryModel._internal(this._gallery);

  void openAlbum(Album album) {
    _openedAlbum = album;
    notifyListeners();
  }

  void closeAlbum() {
    _openedAlbum = null;
    notifyListeners();
  }

  void openMedia(Media media) {
    _openedMedia = media;
    notifyListeners();
  }

  void closeMedia() {
    _openedMedia = null;
    notifyListeners();
  }

  Future<void> getAllAlbums() async {
    return _gallery.getAllAlbums();
  }

  Future<void> getAlbumMedias(String albumName) async {
    return _gallery.getAlbumMedias(openedAlbum.name);
  }

  Future<File> loadAlbumThumbnail(String albumName) async {
    return _gallery.loadAlbumThumbnail(albumName);
  }

  Future<File> loadMediaThumbnail(Uuid id) async {
    return _gallery.loadMediaThumbnail(id);
  }

  CancellableFuture<File> loadMedia(Uuid id) {
    return _gallery.loadMedia(id);
  }

  CancellableFuture<void> put(Uuid id, String albumName, File media) {
    return CancellableFuture((state) async {
      await _gallery.put(id, albumName, media).rebindState(state);
      notifyListeners();
    });
  }

  CancellableFuture<void> copyMedias(List<Uuid> ids, String destinationAlbum) {
    return CancellableFuture((state) async {
      try {
        for (final id in ids) {
          await _gallery
              .copyMedia(id, destinationAlbum, Uuid.generate())
              .rebindState(state);
        }

        notifyListeners();
      } on CancelledException {
        notifyListeners();
      }
    });
  }

  Future<void> moveMedias(List<Uuid> ids, String destinationAlbum) async {
    for (final id in ids) {
      await _gallery.moveMediaToAlbum(id, destinationAlbum);
    }

    notifyListeners();
  }

  Future<void> renameAlbum(String oldName, String newName) async {
    await _gallery.renameAlbum(oldName, newName);
    notifyListeners();
  }

  Future<void> renameMedia(Uuid id, String newName) async {
    await _gallery.renameMedia(id, newName);
    notifyListeners();
  }

  Future<void> deleteAlbums(List<String> albumNames) async {
    for (final name in albumNames) {
      for (final media in await _gallery.getAlbumMedias(name)) {
        await _gallery.delete(media.id);
      }
    }

    notifyListeners();
  }

  Future<void> deleteMedias(List<Uuid> ids) async {
    for (final id in ids) {
      await _gallery.delete(id);
    }

    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _gallery.dispose();
    super.dispose();
  }
}
