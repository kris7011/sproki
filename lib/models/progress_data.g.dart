// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progress_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProgressDataAdapter extends TypeAdapter<ProgressData> {
  @override
  final int typeId = 2;

  @override
  ProgressData read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProgressData(
      childId: fields[0] as String,
      totalStars: fields[1] as int,
      masteredWords: fields[2] as int,
      averageSuccessRate: fields[3] as double,
      createdAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, ProgressData obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.childId)
      ..writeByte(1)
      ..write(obj.totalStars)
      ..writeByte(2)
      ..write(obj.masteredWords)
      ..writeByte(3)
      ..write(obj.averageSuccessRate)
      ..writeByte(4)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressDataAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
