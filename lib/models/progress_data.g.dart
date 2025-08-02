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
      wordId: fields[0] as String,
      totalAttempts: fields[1] as int,
      successfulAttempts: fields[2] as int,
      firstAttempt: fields[3] as DateTime,
      lastAttempt: fields[4] as DateTime,
      isUnlocked: fields[5] as bool,
      bestScore: fields[6] as double,
      sessionDates: (fields[7] as List).cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProgressData obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.wordId)
      ..writeByte(1)
      ..write(obj.totalAttempts)
      ..writeByte(2)
      ..write(obj.successfulAttempts)
      ..writeByte(3)
      ..write(obj.firstAttempt)
      ..writeByte(4)
      ..write(obj.lastAttempt)
      ..writeByte(5)
      ..write(obj.isUnlocked)
      ..writeByte(6)
      ..write(obj.bestScore)
      ..writeByte(7)
      ..write(obj.sessionDates);
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
