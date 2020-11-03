import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:quiver/core.dart';

import 'uuid.dart';

part 'media_metadata.g.dart';

@HiveType(typeId: 2)
enum MediaType {
  @HiveField(0)
  image,

  @HiveField(1)
  video
}

@HiveType(typeId: 3)
class MediaMetadata extends HiveObject {
  @HiveField(0)
  final Uuid id;

  @HiveField(1)
  final String album;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final List<int> salt;

  @HiveField(4)
  final DateTime storeDateTime;

  @HiveField(5)
  final MediaType type;

  MediaMetadata(
      {@required this.id,
      @required String album,
      @required String name,
      @required this.salt,
      @required this.storeDateTime,
      @required this.type})
      : assert(album.trim().isNotEmpty),
        assert(name.trim().isNotEmpty),
        assert(salt.isNotEmpty),
        album = album.trim(),
        name = name.trim();

  @override
  bool operator ==(dynamic other) =>
      other is MediaMetadata && hashCode == other.hashCode;

  @override
  int get hashCode => hashObjects([album, name, ...salt, storeDateTime, type]);

  MediaMetadata copy(
      {Uuid id,
      String album,
      String name,
      Uint8List salt,
      DateTime storeDateTime,
      MediaType type}) {
    return MediaMetadata(
        id: id ?? this.id,
        album: album ?? this.album,
        name: name ?? this.name,
        salt: salt ?? this.salt,
        storeDateTime: storeDateTime ?? this.storeDateTime,
        type: type ?? this.type);
  }
}
