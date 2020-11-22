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
  static const _boxName = 'media_metadata';

  final Future<Box<MediaMetadata>> _futureBox;

  MediaMetadataStore({bool shouldPersist = true})
      : _futureBox = (() async {
          await _HiveInitializer.init();
          return await Hive.openBox<MediaMetadata>(_boxName,
              bytes: shouldPersist ? null : Uint8List.fromList([]));
        })();

  Future<bool> has(Uuid id) async {
    final box = await _futureBox;
    return box.containsKey(id.asString);
  }

  Future<void> put(MediaMetadata metadata) async {
    final box = await _futureBox;

    if (await has(metadata.id)) {
      throw MediaMetadataStoreException('${metadata.id} id already exists.');
    }

    await box.put(metadata.id.asString, metadata);
  }

  Future<MediaMetadata> get(Uuid id) async {
    final box = await _futureBox;

    if (!await has(id)) {
      throw MediaMetadataStoreException('$id id does not exist.');
    }

    return box.get(id.asString);
  }

  Future<List<String>> getAlbumNames() async {
    final box = await _futureBox;
    return box.values.map((m) => m.album).toSet().toList()..sort();
  }

  Future<List<MediaMetadata>> getByAlbum(String name,
      {Comparator<MediaMetadata> sortBy}) async {
    final box = await _futureBox;
    final metas = box.values.where((m) => m.album == name).toList();
    return sortBy != null ? (metas..sort(sortBy)) : metas;
  }

  Future<void> update(List<MediaMetadata> metadatas) async {
    final box = await _futureBox;

    final entries =
        Map.fromEntries(metadatas.map((m) => MapEntry(m.id.asString, m)));
    await box.putAll(entries);
  }

  Future<void> delete(Uuid id) async {
    final box = await _futureBox;
    await box.delete(id.asString);
  }

  Future<void> dispose() async {
    final box = await _futureBox;
    await box.close();
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
