// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compra_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompraModelAdapter extends TypeAdapter<CompraModel> {
  @override
  final int typeId = 3;

  @override
  CompraModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompraModel(
      id: fields[0] as String?,
      dataHoraInicio: fields[1] as DateTime,
      dataHoraFim: fields[2] as DateTime?,
      valorTotalCalculado: fields[3] as double,
      compraStatusId: fields[4] as String,
      isActive: fields[5] as bool,
      isRemoved: fields[6] as bool,
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
      userId: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CompraModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.dataHoraInicio)
      ..writeByte(2)
      ..write(obj.dataHoraFim)
      ..writeByte(3)
      ..write(obj.valorTotalCalculado)
      ..writeByte(4)
      ..write(obj.compraStatusId)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.isRemoved)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.userId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompraModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
