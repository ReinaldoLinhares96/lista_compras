// ignore_for_file: unused_field, avoid_print
import 'dart:math' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/produto_model.dart';
import '../../core/constants/firestore_collections.dart';

class ProdutoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _produtosCollection = FirebaseFirestore.instance
      .collection(FirestoreCollections.produtos);

  // Adicionar um novo produto
  Future<void> addProduto(ProdutoModel produto) async {
    await _produtosCollection.doc(produto.id).set(produto.toFirestore());
  }

  // Obter um produto por ID
  Future<ProdutoModel?> getProdutoById(String id) async {
    final doc = await _produtosCollection.doc(id).get();
    if (doc.exists) {
      return ProdutoModel.fromFirestore(doc);
    }
    return null;
  }

  // Obter todos os produtos ativos (não removidos logicamente)
  // AGORA ORDENADOS POR NOME E FILTRADOS POR ATIVOS
  Stream<List<ProdutoModel>> getActiveProdutos() {
    return _produtosCollection
        .where('isRemoved', isEqualTo: false)
        .orderBy(
          'nome',
          descending: false,
        ) // Adiciona a ordenação por nome (A-Z)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ProdutoModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Atualizar um produto existente
  Future<void> updateProduto(ProdutoModel produto) async {
    // CORREÇÃO: Adicionei um try-catch aqui para pegar o erro exato na origem
    try {
      await _produtosCollection
          .doc(produto.id)
          .update(produto.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e, stacktrace) {
      // Este log deve mostrar a mensagem exata do erro de tipo
      developer.log(
        'Erro ao atualizar produto ${produto.nome} no Firestore: $e\n$stacktrace'
            as num,
      );
      rethrow; // Relança o erro para que a ActiveShoppingPage também o veja
    }
  }

  // Atualiza apenas a quantidade em estoque de um produto
  Future<void> updateQuantidadeEmEstoque(
    String produtoId,
    double novaQuantidade,
  ) async {
    // CORREÇÃO: Adicionei um try-catch aqui também
    try {
      await _produtosCollection.doc(produtoId).update({
        'quantidadeEmEstoque': novaQuantidade,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stacktrace) {
      developer.log(
        'Erro ao atualizar quantidade em estoque para $produtoId no Firestore: $e\n$stacktrace'
            as num,
      );
      rethrow;
    }
  }

  // Remover um produto logicamente
  Future<void> removeProdutoLogically(String id) async {
    await _produtosCollection.doc(id).update({
      'isActive': false,
      'isRemoved': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // (Opcional) Excluir um produto fisicamente (use com cautela!)
  Future<void> deleteProduto(String id) async {
    await _produtosCollection.doc(id).delete();
  }
}
