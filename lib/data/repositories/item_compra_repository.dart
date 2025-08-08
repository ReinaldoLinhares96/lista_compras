// ignore_for_file: depend_on_referenced_packages

import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_compra_model.dart';
import 'package:rxdart/rxdart.dart';

class ItemCompraRepository {
  late Box<ItemCompraModel> _itensCompraBox;

  ItemCompraRepository() {
    _itensCompraBox = Hive.box<ItemCompraModel>('itensCompraBox');
  }

  Future<void> addItemCompra(ItemCompraModel item) async {
    await _itensCompraBox.put(item.id, item);
  }

  Stream<List<ItemCompraModel>> getItensFromActiveCompra(String compraId) {
    return _itensCompraBox
        .watch()
        .map((event) {
          return _itensCompraBox.values
              .where(
                (item) =>
                    item.compraId == compraId &&
                    item.isActive &&
                    !item.isRemoved,
              )
              .toList()
            ..sort((a, b) => a.nomeProduto.compareTo(b.nomeProduto));
        })
        .startWith(
          _itensCompraBox.values
              .where(
                (item) =>
                    item.compraId == compraId &&
                    item.isActive &&
                    !item.isRemoved,
              )
              .toList()
            ..sort((a, b) => a.nomeProduto.compareTo(b.nomeProduto)),
        );
  }

  Future<List<ItemCompraModel>> getItensFromHistoricalCompra(
    String compraId,
  ) async {
    final items = _itensCompraBox.values
        .where((item) => item.compraId == compraId)
        .toList();
    items.sort((a, b) => a.nomeProduto.compareTo(b.nomeProduto));
    return items;
  }

  Stream<List<ItemCompraModel>> watchItensCompra(String compraId) {
    return _itensCompraBox
        .watch()
        .map((event) {
          return _itensCompraBox.values
              .where((item) => item.compraId == compraId)
              .toList();
        })
        .startWith(
          _itensCompraBox.values
              .where((item) => item.compraId == compraId)
              .toList(),
        );
  }

  Future<void> updateItemCompra(ItemCompraModel item) async {
    final existingItem = _itensCompraBox.get(item.id);
    if (existingItem != null) {
      existingItem.nomeProduto = item.nomeProduto;
      existingItem.quantidadeComprada = item.quantidadeComprada;
      existingItem.precoUnitario = item.precoUnitario;
      existingItem.subtotal = item.subtotal;
      existingItem.ehAvulso = item.ehAvulso;
      existingItem.adicionadoNaLista = item.adicionadoNaLista;
      existingItem.isActive = item.isActive;
      existingItem.isRemoved = item.isRemoved;
      existingItem.createdAt = item.createdAt;
      existingItem.updatedAt = DateTime.now();
      await existingItem.save();
    } else {
      await _itensCompraBox.put(item.id, item);
    }
  }

  Future<void> markItemAsRemoved(String itemId) async {
    final item = _itensCompraBox.get(itemId);
    if (item != null) {
      item.isActive = false;
      item.isRemoved = true;
      item.updatedAt = DateTime.now();
      await item.save();
    }
  }

  Future<void> removeItemCompra(String id) async {
    await _itensCompraBox.delete(id);
  }
}
