// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_attempt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WordAttemptAdapter extends TypeAdapter<WordAttempt> {
  @override
  final int typeId = 1;

  @override
  WordAttempt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WordAttempt(
      wordId: fields[0] as String,
      targetWord: fields[1] as String,
      accuracyScore: fields[2] as double,
      attemptTime: fields[3] as DateTime,
      sessionId: fields[4] as int,
      wasSuccessful: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WordAttempt obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.wordId)
      ..writeByte(1)
      ..write(obj.targetWord)
      ..writeByte(2)
      ..write(obj.accuracyScore)
      ..writeByte(3)
      ..write(obj.attemptTime)
      ..writeByte(4)
      ..write(obj.sessionId)
      ..writeByte(5)
      ..write(obj.wasSuccessful);
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
