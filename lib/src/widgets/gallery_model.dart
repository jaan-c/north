import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:north/private_gallery.dart';

class GalleryModel with ChangeNotifier {
  bool get isOpen => _gallery != null;
  List<Album> get allAlbums => _allAlbums;
  String get openedAlbum => _openedAlbum;
  List<Media> get openedAlbumMedias => _openedAlbumMedias;
  Uuid get openedMedia => _openedMedia;

  PrivateGallery _gallery;
  List<Album> _allAlbums = [];
  String _openedAlbum = '';
  List<Media> _openedAlbumMedias = [];
  Uuid _openedMedia;

  Future<void> open(Uint8List key) async {
    if (isOpen) {
      throw StateError('Gallery is already opened.');
    }

    _gallery = await PrivateGallery.instantiate(key);
    _allAlbums = await _gallery.getAllAlbums();
    notifyListeners();
  }

  Future<void> openAlbum(String albumName) async {
    _assertIsOpen();
    _openedAlbum = albumName;
    _openedAlbumMedias = await _gallery.getAlbumMedias(albumName);
    notifyListeners();
  }

  void closeAlbum() {
    _assertIsOpen();
    _openedAlbum = '';
    _openedAlbumMedias = [];
    notifyListeners();
  }

  void openMedia(Uuid id) {
    _assertIsOpen();
    _openedMedia = id;
    notifyListeners();
  }

  void closeMedia() {
    _assertIsOpen();
    _openedMedia = null;
    notifyListeners();
  }

  Future<void> getAllAlbums() async {
    _assertIsOpen();
    return _gallery.getAllAlbums();
  }

  Future<void> getOpenedAlbumMedias() async {
    _assertIsOpen();
    return _gallery.getAlbumMedias(openedAlbum);
  }

  Future<File> loadAlbumThumbnail(String albumName) async {
    _assertIsOpen();
    return _gallery.loadAlbumThumbnail(albumName);
  }

  Future<File> loadMediaThumbnail(Uuid id) async {
    _assertIsOpen();
    return _gallery.loadMediaThumbnail(id);
  }

  CancellableFuture<File> loadMedia(Uuid id) {
    _assertIsOpen();
    return _gallery.loadMedia(id);
  }

  CancellableFuture<void> put(Uuid id, String albumName, File media) {
    return CancellableFuture((state) async {
      _assertIsOpen();
      await _gallery.put(id, albumName, media).rebindState(state);
      notifyListeners();
    });
  }

  CancellableFuture<void> copyMedia(Uuid id, String destinationAlbum) {
    return CancellableFuture((state) async {
      _assertIsOpen();
      await _gallery
          .copyMedia(id, destinationAlbum, Uuid.generate())
          .rebindState(state);
      notifyListeners();
    });
  }

  Future<void> moveMediaToAlbum(Uuid id, String destinationAlbum) async {
    _assertIsOpen();
    await _gallery.moveMediaToAlbum(id, destinationAlbum);
    notifyListeners();
  }

  Future<void> renameAlbum(String oldName, String newName) async {
    _assertIsOpen();
    await _gallery.renameAlbum(oldName, newName);
    notifyListeners();
  }

  Future<void> renameMedia(Uuid id, String newName) async {
    _assertIsOpen();
    await _gallery.renameMedia(id, newName);
    notifyListeners();
  }

  Future<void> deleteAlbum(String albumName) async {
    _assertIsOpen();

    for (final media in await _gallery.getAlbumMedias(albumName)) {
      await _gallery.delete(media.id);
    }

    notifyListeners();
  }

  Future<void> deleteMedia(Uuid id) async {
    _assertIsOpen();
    await _gallery.delete(id);
    notifyListeners();
  }

  @override
  void dispose() {
    _assertIsOpen();
    _gallery.dispose();
    super.dispose();
  }

  void _assertIsOpen() {
    if (!isOpen) {
      throw StateError('Gallery is closed.');
    }
  }
}
