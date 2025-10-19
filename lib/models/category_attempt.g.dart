// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_attempt.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoryAttemptAdapter extends TypeAdapter<CategoryAttempt> {
  @override
  final int typeId = 4;

  @override
  CategoryAttempt read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryAttempt(
      childId: fields[0] as String,
      wordId: fields[1] as String,
      chosenCategory: fields[2] as String,
      correctCategory: fields[3] as String,
      wasCorrect: fields[4] as bool,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryAttempt obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.childId)
      ..writeByte(1)
      ..write(obj.wordId)
      ..writeByte(2)
      ..write(obj.chosenCategory)
      ..writeByte(3)
      ..write(obj.correctCategory)
      ..writeByte(4)
      ..write(obj.wasCorrect)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryAttemptAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
