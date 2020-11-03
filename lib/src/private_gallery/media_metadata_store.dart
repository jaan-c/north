import 'dart:async';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'media_metadata.dart';
import 'uuid.dart';

class MediaMetadataStoreException implements Exception {
  final String message;
  MediaMetadataStoreException(this.message);
  @override
  String toString() => 'MediaMetadataStorageException: $message';
}

class MediaMetadataStore {
  static const _boxName = 'media_metadata';

  final Future<Box<MediaMetadata>> _futureBox;

  MediaMetadataStore({bool shouldPersist = true})
      : _futureBox = (() async {
          await _HiveInitializer.init();
          return await Hive.openBox<MediaMetadata>(_boxName,
              bytes: shouldPersist ? null : Uint8List.fromList([]));
        })();

  Future<void> put(Uuid id, MediaMetadata metadata) async {
    final box = await _futureBox;

    if (box.containsKey(id.asString)) {
      throw MediaMetadataStoreException('$id id already exists.');
    }

    await box.put(id.asString, metadata);
  }

  Future<MediaMetadata> get(Uuid id) async {
    final box = await _futureBox;

    if (!box.containsKey(id.asString)) {
      throw MediaMetadataStoreException('$id id does not exist.');
    }

    return box.get(id.asString);
  }

  Future<List<String>> getAllAlbums() async {
    final box = await _futureBox;
    return box.values.map((m) => m.album).toSet().toList()..sort();
  }

  Future<List<MediaMetadata>> getByAlbum(String name) async {
    final box = await _futureBox;
    return box.values.where((m) => m.album == name).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> delete(Uuid id) async {
    final box = await _futureBox;

    if (!box.containsKey(id.asString)) {
      throw MediaMetadataStoreException('$id id does not exist.');
    }

    await box.delete(id.asString);
  }

  Future<void> close() async {
    final box = await _futureBox;
    await box.close();
  }
}

class _HiveInitializer {
  static var _isInitialized = false;

  static Future<void> init() async {
    if (!_isInitialized) {
      await Hive.initFlutter();
      Hive.registerAdapter(MediaTypeAdapter());
      Hive.registerAdapter(MediaMetadataAdapter());

      _isInitialized = true;
    }
  }
}
