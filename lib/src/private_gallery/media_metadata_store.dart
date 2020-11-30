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
  String toString() => '${(MediaMetadataStoreException)}: $message';
}

class MediaMetadataStore {
  static const _boxName = 'media_metadatas';

  static Future<MediaMetadataStore> instantiate(
      {bool shouldPersist = true}) async {
    await _HiveInitializer.init();
    final box = await Hive.openBox<MediaMetadata>(_boxName,
        bytes: shouldPersist ? null : Uint8List.fromList([]));

    return MediaMetadataStore._internal(box);
  }

  final Box<MediaMetadata> _box;

  MediaMetadataStore._internal(this._box);

  Future<bool> has(Uuid id) async {
    return _box.containsKey(id.asString);
  }

  Future<void> put(MediaMetadata metadata) async {
    if (await has(metadata.id)) {
      throw MediaMetadataStoreException('${metadata.id} id already exists.');
    }

    await _box.put(metadata.id.asString, metadata);
  }

  Future<MediaMetadata> get(Uuid id) async {
    if (!await has(id)) {
      throw MediaMetadataStoreException('$id id does not exist.');
    }

    return _box.get(id.asString);
  }

  Future<List<String>> getAlbumNames() async {
    return _box.values.map((m) => m.album).toSet().toList()..sort();
  }

  Future<List<MediaMetadata>> getByAlbum(String name,
      {Comparator<MediaMetadata> sortBy}) async {
    final metas = _box.values.where((m) => m.album == name).toList();

    return sortBy != null ? (metas..sort(sortBy)) : metas;
  }

  Future<void> update(List<MediaMetadata> metadatas) async {
    final entries =
        Map.fromEntries(metadatas.map((m) => MapEntry(m.id.asString, m)));

    await _box.putAll(entries);
  }

  Future<void> delete(Uuid id) async {
    await _box.delete(id.asString);
  }

  Future<void> dispose() async {
    await _box.close();
  }
}

class _HiveInitializer {
  static var _isInitialized = false;

  static Future<void> init() async {
    if (!_isInitialized) {
      await Hive.initFlutter();
      Hive.registerAdapter(UuidAdapter());
      Hive.registerAdapter(MediaTypeAdapter());
      Hive.registerAdapter(MediaMetadataAdapter());

      _isInitialized = true;
    }
  }
}
