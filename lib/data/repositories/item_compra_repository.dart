// ignore_for_file: depend_on_referenced_packages

import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_compra_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NOVO IMPORT
import 'package:firebase_auth/firebase_auth.dart'; // NOVO IMPORT

class ItemCompraRepository {
  late Box<ItemCompraModel> _itensCompraBox;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ItemCompraRepository() {
    _itensCompraBox = Hive.box<ItemCompraModel>('itensCompraBox');
  }

  CollectionReference<Map<String, dynamic>> _getFirestoreCollection(
    String userId,
    String compraId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('compras')
        .doc(compraId)
        .collection('itensCompra');
  }

  Future<void> addItemCompra(ItemCompraModel item) async {
    final user = _auth.currentUser;
    final itemComUserId = item.copyWith(userId: user?.uid);

    await _itensCompraBox.put(itemComUserId.id, itemComUserId);

    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection(
        user.uid,
        itemComUserId.compraId,
      ).doc(itemComUserId.id).set(itemComUserId.toFirestore());
    }
  }

  // NOVO: Método para obter itens da compra ATIVA (filtrando por ativos e não removidos)
  Stream<List<ItemCompraModel>> getItensFromActiveCompra(String compraId) {
    final user = _auth.currentUser;
    if (user != null) {
      // && verificar status premium
      return _getFirestoreCollection(user.uid, compraId)
          .where('isActive', isEqualTo: true)
          .where('isRemoved', isEqualTo: false)
          .orderBy('nomeProduto', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ItemCompraModel.fromFirestore(doc))
                .toList(),
          )
          .startWith([]);
    } else {
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
  }

  // NOVO: Método para obter itens de uma compra HISTÓRICA (incluindo os logicamente removidos)
  Future<List<ItemCompraModel>> getItensFromHistoricalCompra(
    String compraId,
  ) async {
    final user = _auth.currentUser;
    if (user != null) {
      // && verificar status premium
      final querySnapshot = await _getFirestoreCollection(
        user.uid,
        compraId,
      ).get();
      final items = querySnapshot.docs
          .map((doc) => ItemCompraModel.fromFirestore(doc))
          .toList();
      items.sort((a, b) => a.nomeProduto.compareTo(b.nomeProduto));
      return items;
    } else {
      final items = _itensCompraBox.values
          .where((item) => item.compraId == compraId)
          .toList();
      items.sort((a, b) => a.nomeProduto.compareTo(b.nomeProduto));
      return items;
    }
  }

  Future<ItemCompraModel?> getItemCompraById(String id) async {
    final user = _auth.currentUser;
    if (user != null) {
      // && verificar status premium
      // Isso exigiria o compraId para saber a subcoleção, o que não temos aqui.
      // Poderia ser uma query recursiva se Firestore permitisse, ou uma coleção flat.
      // Por agora, apenas buscar no Hive para simplicidade.
      return _itensCompraBox.get(id);
    } else {
      return _itensCompraBox.get(id);
    }
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
    final user = _auth.currentUser;
    final itemComUserId = item.copyWith(
      userId: user?.uid,
      updatedAt: DateTime.now(),
    );

    await _itensCompraBox.put(itemComUserId.id, itemComUserId);

    if (user != null) {
      // && verificar status premium
      await _getFirestoreCollection(
        user.uid,
        itemComUserId.compraId,
      ).doc(itemComUserId.id).update(itemComUserId.toFirestore());
    }
  }

  Future<void> markItemAsRemoved(String itemId) async {
    final user = _auth.currentUser;

    final itemHive = _itensCompraBox.get(itemId);
    if (itemHive != null) {
      itemHive.isActive = false;
      itemHive.isRemoved = true;
      itemHive.updatedAt = DateTime.now();
      await itemHive.save();
    }

    if (user != null) {
      // && verificar status premium
      // Firestore precisa do compraId para a subcoleção
      if (itemHive != null && itemHive.compraId.isNotEmpty) {
        await _getFirestoreCollection(
          user.uid,
          itemHive.compraId,
        ).doc(itemId).update({
          'isActive': false,
          'isRemoved': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  Future<void> removeItemCompra(String itemId) async {
    final user = _auth.currentUser;

    await _itensCompraBox.delete(itemId);

    if (user != null) {
      // && verificar status premium
      // Firestore precisa do compraId para a subcoleção
      final itemToDelete = await getItemCompraById(
        itemId,
      ); // Tentar buscar no Hive primeiro
      if (itemToDelete != null && itemToDelete.compraId.isNotEmpty) {
        await _getFirestoreCollection(
          user.uid,
          itemToDelete.compraId,
        ).doc(itemId).delete();
      }
    }
  }
}
