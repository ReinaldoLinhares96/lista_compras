// ignore_for_file: avoid_print, depend_on_referenced_packages, unused_field

import 'package:hive_flutter/hive_flutter.dart';
import '../models/produto_model.dart';
import 'package:rxdart/rxdart.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // NOVO IMPORT
import 'package:firebase_auth/firebase_auth.dart'; // NOVO IMPORT
import 'user_repository.dart';

class ProdutoRepository {
  late Box<ProdutoModel> _produtosBox;
  // CORREÇÃO AQUI: Removido a inicialização da declaração
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserRepository _userRepository;
  ProdutoRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    required UserRepository userRepository, // NOVO: Receber UserRepository
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _userRepository = userRepository {
    _produtosBox = Hive.box<ProdutoModel>('produtosBox');
  }

  // --- Método Auxiliar para Obter a Coleção Correta (Hive ou Firestore) ---
  CollectionReference<Map<String, dynamic>> _getFirestoreCollection(
    String userId,
  ) {
    // Exemplo: /users/{userId}/produtos
    return _firestore.collection('users').doc(userId).collection('produtos');
  }

  // --- Lógica de CRUD com Dupla Personalidade ---

  Future<void> addProduto(ProdutoModel produto) async {
    final user = _auth.currentUser;
    // Ao adicionar, o produto recebe o userId do usuário logado.
    final produtoComUserId = produto.copyWith(userId: user?.uid);

    // Salvar no Hive (sempre para o modo offline/gratuito)
    await _produtosBox.put(produtoComUserId.id, produtoComUserId);

    // Se o usuário estiver logado (e for premium, que será verificado posteriormente),
    // salvar também no Firestore.
    if (user != null) {
      // && user.isPremium (futuro)
      await _getFirestoreCollection(
        user.uid,
      ).doc(produtoComUserId.id).set(produtoComUserId.toFirestore());
    }
  }

  Future<ProdutoModel?> getProdutoById(String id) async {
    final user = _auth.currentUser;
    if (user != null) {
      // && user.isPremium (futuro)
      final doc = await _getFirestoreCollection(user.uid).doc(id).get();
      return doc.exists ? ProdutoModel.fromFirestore(doc) : null;
    } else {
      return _produtosBox.get(id);
    }
  }

  Stream<List<ProdutoModel>> getActiveProdutos() {
    // CORREÇÃO: Usar .values.toList() para pegar uma nova lista a cada evento
    // E garantir que o filtro e ordenação são aplicados sobre os valores ATUAIS da box.
    final user = _auth.currentUser;

    if (user != null) {
      // && user.isPremium (futuro)
      // Se usuário logado, observar o Firestore
      return _getFirestoreCollection(user.uid)
          .where('isRemoved', isEqualTo: false)
          .orderBy('nome', descending: false)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => ProdutoModel.fromFirestore(doc))
                .toList(),
          )
          .startWith([]); // Emissão inicial vazia para StreamBuilder
    } else {
      return _produtosBox
          .watch()
          .map((event) {
            final allProdutos = _produtosBox.values
                .where((p) => !p.isRemoved)
                .toList();
            allProdutos.sort(
              (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
            );
            return allProdutos;
          })
          .startWith(_produtosBox.values.where((p) => !p.isRemoved).toList());
    } // Emitir o estado inicial filtrado
  }

  Future<void> updateProduto(ProdutoModel produto) async {
    final user = _auth.currentUser;
    final produtoComUserId = produto.copyWith(
      userId: user?.uid,
      updatedAt: DateTime.now(),
    );

    // Atualizar no Hive
    final existingProdutoHive = _produtosBox.get(produtoComUserId.id);
    if (existingProdutoHive != null) {
      existingProdutoHive.nome = produtoComUserId.nome;
      existingProdutoHive.quantidadeIdealMes =
          produtoComUserId.quantidadeIdealMes;
      existingProdutoHive.categoriaId = produtoComUserId.categoriaId;
      existingProdutoHive.quantidadeEmEstoque =
          produtoComUserId.quantidadeEmEstoque;
      existingProdutoHive.isActive = produtoComUserId.isActive;
      existingProdutoHive.isRemoved = produtoComUserId.isRemoved;
      existingProdutoHive.createdAt = produtoComUserId.createdAt;
      existingProdutoHive.updatedAt = produtoComUserId.updatedAt;
      existingProdutoHive.userId =
          produtoComUserId.userId; // Atualiza o userId também
      await existingProdutoHive.save();
    } else {
      await _produtosBox.put(produtoComUserId.id, produtoComUserId);
    }

    // Se o usuário estiver logado, atualizar no Firestore
    if (user != null) {
      // && user.isPremium (futuro)
      await _getFirestoreCollection(
        user.uid,
      ).doc(produtoComUserId.id).update(produtoComUserId.toFirestore());
    }
  }

  Future<void> updateQuantidadeEmEstoque(
    String produtoId,
    int novaQuantidade,
  ) async {
    final user = _auth.currentUser;

    // Atualizar no Hive
    final produtoHive = _produtosBox.get(produtoId);
    if (produtoHive != null) {
      produtoHive.quantidadeEmEstoque = novaQuantidade;
      produtoHive.updatedAt = DateTime.now();
      await produtoHive.save();
    }

    // Se o usuário estiver logado, atualizar no Firestore
    if (user != null) {
      // && user.isPremium (futuro)
      await _getFirestoreCollection(user.uid).doc(produtoId).update({
        'quantidadeEmEstoque': novaQuantidade,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> removeProdutoLogically(String id) async {
    final user = _auth.currentUser;

    // Remover logicamente no Hive
    final produtoHive = _produtosBox.get(id);
    if (produtoHive != null) {
      produtoHive.isActive = false;
      produtoHive.isRemoved = true;
      produtoHive.updatedAt = DateTime.now();
      await produtoHive.save();
    }

    // Se o usuário estiver logado, remover logicamente no Firestore
    if (user != null) {
      // && user.isPremium (futuro)
      await _getFirestoreCollection(user.uid).doc(id).update({
        'isActive': false,
        'isRemoved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteProduto(String id) async {
    final user = _auth.currentUser;

    // Deletar fisicamente no Hive
    await _produtosBox.delete(id);

    // Se o usuário estiver logado, deletar fisicamente no Firestore
    if (user != null) {
      // && user.isPremium (futuro)
      await _getFirestoreCollection(user.uid).doc(id).delete();
    }
  }
}
