import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../commons.dart';
import 'media_metadata.dart';

class MediaMetadataStoreException implements Exception {
  final String message;
  MediaMetadataStoreException(this.message);
  String toString() => "MediaMetadataStorageException: $message";
}

class MediaMetadataStore {
  static const _boxName = "media_metadata";

  static Future<MediaMetadataStore> init() async {
    await Hive.initFlutter();
    try {
      Hive.registerAdapter(MediaTypeAdapter());
    } on HiveError {}
    try {
      Hive.registerAdapter(MediaMetadataAdapter());
    } on HiveError {}

    final box = await Hive.openBox<MediaMetadata>(_boxName);
    return MediaMetadataStore._internal(box);
  }

  final Box<MediaMetadata> _box;

  MediaMetadataStore._internal(this._box);

  Future<void> store(Uuid id, MediaMetadata metadata) async {
    _assertIdNotExists(id);
    await _box.put(id.toString(), metadata);
  }

  Future<MediaMetadata> query(Uuid id) async {
    _assertIdExists(id);
    return _box.get(id.toString());
  }

  Future<void> delete(Uuid id) async {
    _assertIdExists(id);
    _box.delete(id.toString());
  }

  void _assertIdNotExists(Uuid id) {
    if (_box.containsKey(id.toString())) {
      throw MediaMetadataStoreException("$id id exists.");
    }
  }

  void _assertIdExists(Uuid id) {
    if (!_box.containsKey(id.toString())) {
      throw MediaMetadataStoreException("$id id does not exist.");
    }
  }
}
