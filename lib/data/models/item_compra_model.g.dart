// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_compra_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemCompraModelAdapter extends TypeAdapter<ItemCompraModel> {
  @override
  final int typeId = 4;

  @override
  ItemCompraModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemCompraModel(
      id: fields[0] as String?,
      compraId: fields[1] as String,
      produtoId: fields[2] as String?,
      nomeProduto: fields[3] as String,
      quantidadeComprada: fields[4] as int,
      precoUnitario: fields[5] as double,
      subtotal: fields[6] as double?,
      ehAvulso: fields[7] as bool?,
      adicionadoNaLista: fields[8] as bool?,
      isActive: fields[11] as bool?,
      isRemoved: fields[12] as bool?,
      createdAt: fields[9] as DateTime?,
      updatedAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ItemCompraModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.compraId)
      ..writeByte(2)
      ..write(obj.produtoId)
      ..writeByte(3)
      ..write(obj.nomeProduto)
      ..writeByte(4)
      ..write(obj.quantidadeComprada)
      ..writeByte(5)
      ..write(obj.precoUnitario)
      ..writeByte(6)
      ..write(obj.subtotal)
      ..writeByte(7)
      ..write(obj.ehAvulso)
      ..writeByte(8)
      ..write(obj.adicionadoNaLista)
      ..writeByte(9)
      ..write(obj.createdAt)
      ..writeByte(10)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.isActive)
      ..writeByte(12)
      ..write(obj.isRemoved);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemCompraModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
