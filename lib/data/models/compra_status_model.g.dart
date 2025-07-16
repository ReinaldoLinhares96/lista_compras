// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compra_status_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompraStatusModelAdapter extends TypeAdapter<CompraStatusModel> {
  @override
  final int typeId = 5;

  @override
  CompraStatusModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompraStatusModel(
      id: fields[0] as String,
      descricao: fields[1] as String,
      isActive: fields[2] as bool,
      isRemoved: fields[3] as bool,
      userId: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CompraStatusModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.descricao)
      ..writeByte(2)
      ..write(obj.isActive)
      ..writeByte(3)
      ..write(obj.isRemoved)
      ..writeByte(4)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompraStatusModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
