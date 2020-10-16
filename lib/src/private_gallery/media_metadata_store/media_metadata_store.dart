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

  final Future<Box<MediaMetadata>> _futureBox;

  MediaMetadataStore()
      : _futureBox = (() async {
          await Hive.initFlutter();
          Hive.silentRegisterAdapter(MediaTypeAdapter());
          Hive.silentRegisterAdapter(MediaMetadataAdapter());

          return await Hive.openBox<MediaMetadata>(_boxName);
        })();

  Future<void> put(Uuid id, MediaMetadata metadata) async {
    final box = await _futureBox;

    if (box.containsKey(id.toString())) {
      throw MediaMetadataStoreException("$id id already exists.");
    }

    await box.put(id.toString(), metadata);
  }

  Future<MediaMetadata> get(Uuid id) async {
    final box = await _futureBox;

    if (!box.containsKey(id.toString())) {
      throw MediaMetadataStoreException("$id id does not exist.");
    }

    return box.get(id.toString());
  }

  Future<void> delete(Uuid id) async {
    final box = await _futureBox;

    if (!box.containsKey(id.toString())) {
      throw MediaMetadataStoreException("$id id does not exist.");
    }

    box.delete(id.toString());
  }
}

extension _SilentAdapterRegistrar on HiveInterface {
  void silentRegisterAdapter<T>(TypeAdapter<T> adapter) {
    try {
      this.registerAdapter(adapter);
    } on HiveError {}
  }
}
