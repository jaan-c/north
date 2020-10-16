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
    Hive.silentRegisterAdapter(MediaTypeAdapter());
    Hive.silentRegisterAdapter(MediaMetadataAdapter());

    final box = await Hive.openBox<MediaMetadata>(_boxName);
    return MediaMetadataStore._internal(box);
  }

  final Box<MediaMetadata> _box;

  MediaMetadataStore._internal(this._box);

  Future<void> put(Uuid id, MediaMetadata metadata) async {
    if (_box.containsKey(id.toString())) {
      throw MediaMetadataStoreException("$id id already exists.");
    }

    await _box.put(id.toString(), metadata);
  }

  Future<MediaMetadata> get(Uuid id) async {
    if (!_box.containsKey(id.toString())) {
      throw MediaMetadataStoreException("$id id does not exist.");
    }

    return _box.get(id.toString());
  }

  Future<void> delete(Uuid id) async {
    if (!_box.containsKey(id.toString())) {
      throw MediaMetadataStoreException("$id id does not exist.");
    }

    _box.delete(id.toString());
  }
}

extension _SilentAdapterRegistrar on HiveInterface {
  void silentRegisterAdapter<T>(TypeAdapter<T> adapter) {
    try {
      this.registerAdapter(adapter);
    } on HiveError {}
  }
}
