// ignore_for_file: avoid_print, depend_on_referenced_packages

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
  }

  Future<void> updateProduto(ProdutoModel produto) async {
    await _produtosBox.put(produto.id, produto);
  }

  Future<void> updateQuantidadeEmEstoque(
    String produtoId,
    int novaQuantidade,
  ) async {
    final produto = _produtosBox.get(produtoId);
    if (produto != null) {
      produto.quantidadeEmEstoque = novaQuantidade;
      produto.updatedAt = DateTime.now();
      await produto.save();
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
