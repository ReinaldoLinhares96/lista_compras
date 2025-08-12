// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'premium_status_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PremiumStatusModelAdapter extends TypeAdapter<PremiumStatusModel> {
  @override
  final int typeId = 7;

  @override
  PremiumStatusModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PremiumStatusModel(
      id: fields[0] as String,
      isPremium: fields[1] as bool,
      createdAt: fields[2] as DateTime,
      updatedAt: fields[3] as DateTime,
      isActive: fields[4] as bool,
      isRemoved: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PremiumStatusModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isPremium)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.isActive)
      ..writeByte(5)
      ..write(obj.isRemoved);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PremiumStatusModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
