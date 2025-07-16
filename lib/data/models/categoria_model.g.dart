// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categoria_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CategoriaModelAdapter extends TypeAdapter<CategoriaModel> {
  @override
  final int typeId = 2;

  @override
  CategoriaModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoriaModel(
      id: fields[0] as String?,
      descricao: fields[1] as String,
      isActive: fields[2] as bool,
      isRemoved: fields[3] as bool,
      userId: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CategoriaModel obj) {
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
      other is CategoriaModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
