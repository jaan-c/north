import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:quiver/core.dart';

import 'uuid.dart';

part 'media_metadata.g.dart';

@HiveType(typeId: 3)
class MediaMetadata extends HiveObject {
  @HiveField(0)
  final Uuid id;

  @HiveField(1)
  final String album;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final DateTime storeDateTime;

  MediaMetadata(
      {@required this.id,
      @required String album,
      @required String name,
      @required this.storeDateTime})
      : assert(album.trim().isNotEmpty),
        assert(name.trim().isNotEmpty),
        album = album.trim(),
        name = name.trim();

  @override
  bool operator ==(dynamic other) =>
      other is MediaMetadata && hashCode == other.hashCode;

  @override
  int get hashCode => hash3(album, name, storeDateTime);

  MediaMetadata copy(
      {Uuid id, String album, String name, DateTime storeDateTime}) {
    return MediaMetadata(
        id: id ?? this.id,
        album: album ?? this.album,
        name: name ?? this.name,
        storeDateTime: storeDateTime ?? this.storeDateTime);
  }
}
