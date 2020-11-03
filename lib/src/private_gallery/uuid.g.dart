// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'uuid.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UuidAdapter extends TypeAdapter<Uuid> {
  @override
  final int typeId = 1;

  @override
  Uuid read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Uuid(fields[0] as String);
  }

  @override
  void write(BinaryWriter writer, Uuid obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.asString);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UuidAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
