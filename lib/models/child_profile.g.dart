// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'child_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ChildProfileAdapter extends TypeAdapter<ChildProfile> {
  @override
  final int typeId = 0;

  @override
  ChildProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ChildProfile(
      name: fields[0] as String,
      birthDate: fields[1] as DateTime,
      challengeAreas: (fields[2] as List).cast<String>(),
      currentLevel: fields[3] as String,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ChildProfile obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.birthDate)
      ..writeByte(2)
      ..write(obj.challengeAreas)
      ..writeByte(3)
      ..write(obj.currentLevel)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChildProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
