// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_metadata.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MediaMetadataAdapter extends TypeAdapter<MediaMetadata> {
  @override
  final int typeId = 3;

  @override
  MediaMetadata read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MediaMetadata(
      id: fields[0] as Uuid,
      album: fields[1] as String,
      name: fields[2] as String,
      storeDateTime: fields[3] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MediaMetadata obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.album)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.storeDateTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MediaMetadataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
