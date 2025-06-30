// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_compra_model.dart';
import '../../core/constants/firestore_collections.dart';

class ItemCompraRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _itensCompraCollection = FirebaseFirestore.instance
      .collection(FirestoreCollections.itensCompra);

  // Adiciona um item a uma compra específica
  Future<void> addItemCompra(ItemCompraModel item) async {
    await _itensCompraCollection.doc(item.id).set(item.toFirestore());
  }

  // Obtém todos os itens de uma compra específica
  Stream<List<ItemCompraModel>> getItensCompra(String compraId) {
    return _itensCompraCollection
        .where('compraId', isEqualTo: compraId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ItemCompraModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Remove um item de uma compra (exclusão física)
  Future<void> removeItemCompra(String itemId) async {
    await _itensCompraCollection.doc(itemId).delete();
  }

  // Atualiza um item de compra (útil para caso o usuário mude qty ou preço de um item já no carrinho)
  Future<void> updateItemCompra(ItemCompraModel item) async {
    await _itensCompraCollection.doc(item.id).update(item.toFirestore());
  }
}
