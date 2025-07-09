// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orcamento_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrcamentoModelAdapter extends TypeAdapter<OrcamentoModel> {
  @override
  final int typeId = 6;

  @override
  OrcamentoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrcamentoModel(
      id: fields[0] as String,
      valorMaximo: fields[1] as double,
      updatedAt: fields[2] as DateTime?,
      isActive: fields[3] as bool,
      isRemoved: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, OrcamentoModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.valorMaximo)
      ..writeByte(2)
      ..write(obj.updatedAt)
      ..writeByte(3)
      ..write(obj.isActive)
      ..writeByte(4)
      ..write(obj.isRemoved);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrcamentoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
