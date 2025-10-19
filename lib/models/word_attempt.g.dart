// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_attempt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordAttemptAdapter extends TypeAdapter<WordAttempt> {
  @override
  final int typeId = 3;

  @override
  WordAttempt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordAttempt(
      childId: fields[0] as String,
      wordId: fields[1] as String,
      word: fields[2] as String,
      score: fields[3] as double,
      createdAt: fields[4] as DateTime,
      firstAttempt: fields[5] as DateTime,
      lastAttempt: fields[6] as DateTime,
      sessionDates: (fields[7] as List).cast<DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, WordAttempt obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.childId)
      ..writeByte(1)
      ..write(obj.wordId)
      ..writeByte(2)
      ..write(obj.word)
      ..writeByte(3)
      ..write(obj.score)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.firstAttempt)
      ..writeByte(6)
      ..write(obj.lastAttempt)
      ..writeByte(7)
      ..write(obj.sessionDates);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WordAttemptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
