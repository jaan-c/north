import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:quiver/core.dart';

part 'media_metadata.g.dart';

@HiveType(typeId: 1)
enum MediaType {
  @HiveField(0)
  image,

  @HiveField(1)
  video
}

@HiveType(typeId: 2)
class MediaMetadata extends HiveObject {
  @HiveField(0)
  final String album;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String salt;

  @HiveField(3)
  final DateTime storeDateTime;

  @HiveField(4)
  final MediaType type;

  MediaMetadata(
      {@required this.album,
      @required this.name,
      @required this.salt,
      @required this.storeDateTime,
      @required this.type});

  @override
  bool operator ==(dynamic other) =>
      other is MediaMetadata && hashCode == other.hashCode;

  @override
  int get hashCode => hashObjects([album, name, salt, storeDateTime, type]);

  MediaMetadata copy(
      {String album,
      String name,
      String salt,
      DateTime storeDateTime,
      MediaType type}) {
    return MediaMetadata(
        album: album ?? this.album,
        name: name ?? this.name,
        salt: salt ?? this.salt,
        storeDateTime: storeDateTime ?? this.storeDateTime,
        type: type ?? this.type);
  }
}
