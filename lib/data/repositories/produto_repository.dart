// ignore_for_file: avoid_print, depend_on_referenced_packages

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/produto_model.dart';
import 'package:rxdart/rxdart.dart';

class ProdutoRepository {
  late Box<ProdutoModel> _produtosBox;

  ProdutoRepository() {
    _produtosBox = Hive.box<ProdutoModel>('produtosBox');
  }

  Future<void> addProduto(ProdutoModel produto) async {
    await _produtosBox.put(produto.id, produto);
  }

  Future<ProdutoModel?> getProdutoById(String id) async {
    return _produtosBox.get(id);
  }

  Stream<List<ProdutoModel>> getActiveProdutos() {
    // CORREÇÃO: Usar .values.toList() para pegar uma nova lista a cada evento
    // E garantir que o filtro e ordenação são aplicados sobre os valores ATUAIS da box.
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
        .startWith(
          _produtosBox.values.where((p) => !p.isRemoved).toList(),
        ); // Emitir o estado inicial filtrado
  }

  Future<void> updateProduto(ProdutoModel produto) async {
    try {
      await _produtosBox.put(produto.id, produto);
    } catch (e, stacktrace) {
      print(
        'Erro ao atualizar produto ${produto.nome} no Hive: $e\n$stacktrace',
      );
      rethrow;
    }
  }

  Future<void> updateQuantidadeEmEstoque(
    String produtoId,
    int novaQuantidade,
  ) async {
    try {
      final produto = _produtosBox.get(produtoId);
      if (produto != null) {
        produto.quantidadeEmEstoque = novaQuantidade;
        produto.updatedAt = DateTime.now();
        await produto.save();
      }
    } catch (e, stacktrace) {
      if (kDebugMode) {
        print(
          'Erro ao atualizar quantidade em estoque para $produtoId no Hive: $e\n$stacktrace',
        );
      }
      rethrow;
    }
  }

  Future<void> removeProdutoLogically(String id) async {
    final produto = _produtosBox.get(id);
    if (produto != null) {
      produto.isActive = false;
      produto.isRemoved = true;
      produto.updatedAt = DateTime.now();
      await produto.save();
    }
  }

  Future<void> deleteProduto(String id) async {
    await _produtosBox.delete(id);
  }
}
