// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unidade_medida_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UnidadeMedidaModelAdapter extends TypeAdapter<UnidadeMedidaModel> {
  @override
  final int typeId = 1;

  @override
  UnidadeMedidaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UnidadeMedidaModel(
      id: fields[0] as String?,
      descricao: fields[1] as String,
      simbolo: fields[2] as String,
      isActive: fields[3] as bool,
      isRemoved: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UnidadeMedidaModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.descricao)
      ..writeByte(2)
      ..write(obj.simbolo)
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
      other is UnidadeMedidaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
