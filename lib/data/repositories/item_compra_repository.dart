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

  // NOVO: Método para obter itens da compra ATIVA (filtrando por ativos e não removidos)
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

  // NOVO: Método para obter itens de uma compra HISTÓRICA (incluindo os logicamente removidos)
  Future<List<ItemCompraModel>> getItensFromHistoricalCompra(
    String compraId,
  ) async {
    // Retorna todos os itens associados a esta compra, independentemente do status isActive/isRemoved
    final items = _itensCompraBox.values
        .where((item) => item.compraId == compraId)
        .toList();
    items.sort((a, b) => a.nomeProduto.compareTo(b.nomeProduto));
    return items;
  }

  // NOVO: Stream para observar mudanças nos itens de uma compra específica
  // Isso é crucial para a ActiveShoppingPage reagir a adições/remoções
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
    // Usar .put() diretamente, mas garantir que o objeto seja o existente se possível
    final existingItem = _itensCompraBox.get(item.id);
    if (existingItem != null) {
      existingItem.nomeProduto = item.nomeProduto;
      existingItem.quantidadeComprada = item.quantidadeComprada;
      existingItem.precoUnitario = item.precoUnitario;
      existingItem.subtotal =
          item.subtotal; // Subtotal pode ser recalculado no modelo
      existingItem.ehAvulso = item.ehAvulso;
      existingItem.adicionadoNaLista = item.adicionadoNaLista;
      existingItem.isActive = item.isActive;
      existingItem.isRemoved = item.isRemoved;
      existingItem.createdAt = item.createdAt;
      existingItem.updatedAt = DateTime.now(); // Atualiza data de modificação
      await existingItem.save();
    } else {
      await _itensCompraBox.put(item.id, item);
    }
  }

  // NOVO: Método para marcar um item como logicamente removido
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
