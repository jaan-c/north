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

  String get openedAlbum => _openedAlbum;
  Uuid get openedMedia => _openedMedia;

  String _openedAlbum = '';
  Uuid _openedMedia;

  GalleryModel._internal(this._gallery);

  Future<void> openAlbum(String albumName) async {
    _openedAlbum = albumName;
    notifyListeners();
  }

  void closeAlbum() {
    _openedAlbum = '';
    notifyListeners();
  }

  void openMedia(Uuid id) {
    _openedMedia = id;
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
    return _gallery.getAlbumMedias(openedAlbum);
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

  CancellableFuture<void> copyMedia(Uuid id, String destinationAlbum) {
    return CancellableFuture((state) async {
      await _gallery
          .copyMedia(id, destinationAlbum, Uuid.generate())
          .rebindState(state);
      notifyListeners();
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

  Future<void> deleteAlbum(String albumName) async {
    for (final media in await _gallery.getAlbumMedias(albumName)) {
      await _gallery.delete(media.id);
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
