// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'produto_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProdutoModelAdapter extends TypeAdapter<ProdutoModel> {
  @override
  final int typeId = 0;

  @override
  ProdutoModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProdutoModel(
      id: fields[0] as String?,
      nome: fields[1] as String,
      quantidadeIdealMes: fields[2] as int,
      categoriaId: fields[3] as String,
      quantidadeEmEstoque: fields[4] as int,
      isActive: fields[5] as bool,
      isRemoved: fields[6] as bool,
      createdAt: fields[7] as DateTime?,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProdutoModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.nome)
      ..writeByte(2)
      ..write(obj.quantidadeIdealMes)
      ..writeByte(3)
      ..write(obj.categoriaId)
      ..writeByte(4)
      ..write(obj.quantidadeEmEstoque)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.isRemoved)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProdutoModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
