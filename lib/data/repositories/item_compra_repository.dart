// ignore_for_file: depend_on_referenced_packages, unused_local_variable

import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_compra_model.dart';
import 'package:rxdart/rxdart.dart';
import 'user_repository.dart'; // NOVO IMPORT: UserRepository

class ItemCompraRepository {
  late Box<ItemCompraModel> _itensCompraBox;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserRepository _userRepository; // NOVO: Instância de UserRepository

  ItemCompraRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required UserRepository userRepository, // NOVO: Receber UserRepository
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _userRepository = userRepository {
    _itensCompraBox = Hive.box<ItemCompraModel>('itensCompraBox');
  }

  // Coleção Firestore: /users/{userId}/compras/{compraId}/itensCompra
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
    final isPremium = _userRepository.isPremium; // Consultar status premium
    final itemComUserId = item.copyWith(
      userId: user?.uid,
    ); // Atribui userId (pode ser null para não logados)

    await _itensCompraBox.put(
      itemComUserId.id,
      itemComUserId,
    ); // Salva no Hive (sempre)

    if (user != null && isPremium) {
      // Se logado E PREMIUM, salva no Firestore
      await _getFirestoreCollection(
        user.uid,
        itemComUserId.compraId,
      ).doc(itemComUserId.id).set(itemComUserId.toFirestore());
    }
  }

  // Método para obter itens da compra ATIVA (Hive ou Firestore)
  Stream<List<ItemCompraModel>> getItensFromActiveCompra(String compraId) {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium; // Consultar status premium

    if (user != null && isPremium) {
      // Usuário logado E PREMIUM: Observa Firestore
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
      // NÃO PREMIUM (inclui anônimo se o fluxo permitisse, ou logado não premium): Observa Hive
      return _itensCompraBox
          .watch()
          .map((event) {
            return _itensCompraBox.values
                .where(
                  (item) =>
                      item.compraId == compraId &&
                      item.isActive &&
                      !item.isRemoved &&
                      // FILTRO userId: Pega itens com userId = UID do usuário atual
                      item.userId ==
                          user?.uid, // user?.uid será null para anônimos, ou o UID do logado
                )
                .toList()
              ..sort(
                (a, b) => a.nomeProduto.toLowerCase().compareTo(
                  b.nomeProduto.toLowerCase(),
                ),
              );
          })
          .startWith(
            _itensCompraBox.values
                .where(
                  (item) =>
                      item.compraId == compraId &&
                      item.isActive &&
                      !item.isRemoved &&
                      item.userId == user?.uid, // FILTRO userId
                )
                .toList()
              ..sort(
                (a, b) => a.nomeProduto.toLowerCase().compareTo(
                  b.nomeProduto.toLowerCase(),
                ),
              ),
          );
    }
  }

  // Método para observar mudanças nos itens de uma compra específica (Hive ou Firestore)
  Stream<List<ItemCompraModel>> watchItensCompra(String compraId) {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;

    if (user != null && isPremium) {
      // Usuário logado E PREMIUM: Observa Firestore
      return _getFirestoreCollection(user.uid, compraId)
          .orderBy('nomeProduto', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ItemCompraModel.fromFirestore(doc))
                .toList(),
          )
          .startWith([]);
    } else {
      // NÃO PREMIUM: Observa Hive
      return _itensCompraBox
          .watch()
          .map((event) {
            return _itensCompraBox.values
                .where(
                  // FILTRO userId: Pega itens com userId = UID do usuário atual
                  (item) =>
                      item.compraId == compraId && item.userId == user?.uid,
                )
                .toList()
              ..sort(
                (a, b) => a.nomeProduto.toLowerCase().compareTo(
                  b.nomeProduto.toLowerCase(),
                ),
              );
          })
          .startWith(
            _itensCompraBox.values
                .where(
                  (item) =>
                      item.compraId == compraId &&
                      item.userId == user?.uid, // FILTRO userId
                )
                .toList()
              ..sort(
                (a, b) => a.nomeProduto.toLowerCase().compareTo(
                  b.nomeProduto.toLowerCase(),
                ),
              ),
          );
    }
  }

  // Método para obter itens de uma compra HISTÓRICA (Hive ou Firestore)
  Future<List<ItemCompraModel>> getItensFromHistoricalCompra(
    String compraId,
  ) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;

    if (user != null && isPremium) {
      // Usuário logado E PREMIUM: Usa Firestore
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
      // NÃO PREMIUM: Usa Hive
      final items = _itensCompraBox.values
          .where(
            (item) => item.compraId == compraId && item.userId == user?.uid,
          ) // FILTRO userId
          .toList();
      items.sort(
        (a, b) =>
            a.nomeProduto.toLowerCase().compareTo(b.nomeProduto.toLowerCase()),
      );
      return items;
    }
  }

  Future<ItemCompraModel?> getItemCompraById(String id) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;

    // A busca por ID em Firestore requer o compraId para a subcoleção
    // Por simplicidade, vamos buscar no Hive para qualquer usuário logado
    // e o userId do item deve corresponder ao userId atual.
    final item = _itensCompraBox.get(id);
    if (item != null && item.userId == user?.uid) {
      return item;
    }
    return null;
  }

  Future<void> updateItemCompra(ItemCompraModel item) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;
    final itemComUserId = item.copyWith(
      userId: user?.uid,
      updatedAt: DateTime.now(),
    );

    await _itensCompraBox.put(
      itemComUserId.id,
      itemComUserId,
    ); // Atualiza no Hive

    if (user != null && isPremium) {
      // Se logado E PREMIUM, atualiza no Firestore
      await _getFirestoreCollection(
        user.uid,
        itemComUserId.compraId,
      ).doc(itemComUserId.id).update(itemComUserId.toFirestore());
    }
  }

  // Método para marcar um item como logicamente removido (para histórico)
  Future<void> markItemAsRemoved(String itemId) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;

    final itemHive = _itensCompraBox.get(itemId);
    if (itemHive != null) {
      itemHive.isActive = false;
      itemHive.isRemoved = true;
      itemHive.updatedAt = DateTime.now();
      await itemHive.save();
    }

    if (user != null && isPremium) {
      // Se logado E PREMIUM, atualiza no Firestore
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

  // Método para remover UM item fisicamente do carrinho ATIVO (Hive ou Firestore)
  Future<void> removeItemCompra(String itemId) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;

    // Remover do Hive
    final itemToDeleteHive = _itensCompraBox.get(itemId);
    if (itemToDeleteHive != null) {
      await _itensCompraBox.delete(itemId);
    }

    if (user != null && isPremium) {
      // Se logado E PREMIUM, tenta remover do Firestore também
      // Firestore precisa do compraId para a subcoleção
      if (itemToDeleteHive != null && itemToDeleteHive.compraId.isNotEmpty) {
        await _getFirestoreCollection(
          user.uid,
          itemToDeleteHive.compraId,
        ).doc(itemId).delete();
      }
    }
  }

  // Método para remover TODOS os itens de uma compra (ex: ao finalizar/cancelar)
  // Faz a remoção física no Hive e no Firestore.
  Future<void> removeAllItensFromCompra(String compraId) async {
    final user = _auth.currentUser;
    final isPremium = _userRepository.isPremium;

    // Remover do Hive
    final itensToRemoveHive = _itensCompraBox.values
        .where((item) => item.compraId == compraId && item.userId == user?.uid)
        .toList(); // Filtro userId
    for (var item in itensToRemoveHive) {
      await _itensCompraBox.delete(item.id); // Deleta do Hive fisicamente
    }

    if (user != null && isPremium) {
      // Se logado E PREMIUM, remove do Firestore
      // Remover do Firestore: precisa buscar todos os itens da subcoleção e deletar
      final querySnapshot = await _getFirestoreCollection(
        user.uid,
        compraId,
      ).get();
      for (var doc in querySnapshot.docs) {
        await doc.reference.delete();
      }
    }
  }
}
