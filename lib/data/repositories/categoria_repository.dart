// ignore_for_file: depend_on_referenced_packages, cast_from_null_always_fails, unnecessary_brace_in_string_interps, unused_import

import 'dart:math' as developer;

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lista_compras/presentation/pages/active_shopping_page.dart';
import '../models/categoria_model.dart';
import 'package:rxdart/rxdart.dart';

class CategoriaRepository {
  late Box<CategoriaModel> _categoriasBox;

  CategoriaRepository() {
    _categoriasBox = Hive.box<CategoriaModel>('categoriasBox');
  }

  Stream<List<CategoriaModel>> getCategorias() {
    // Filtrar apenas categorias ativas
    return _categoriasBox
        .watch()
        .map((event) {
          final allCategorias = _categoriasBox.values
              .where((c) => c.isActive && !c.isRemoved)
              .toList(); // FILTRO AQUI
          allCategorias.sort(
            (a, b) =>
                a.descricao.toLowerCase().compareTo(b.descricao.toLowerCase()),
          );
          return allCategorias;
        })
        .startWith(
          _categoriasBox.values
              .where((c) => c.isActive && !c.isRemoved)
              .toList(),
        ); // Emissão inicial filtrada
  }

  Future<void> addCategoria(CategoriaModel categoria) async {
    if (kDebugMode) {
      print('DEBUG: entrou em addCategoria. Categoria: ${categoria}');
    }
    await _categoriasBox.put(categoria.id, categoria);
    if (kDebugMode) {
      print('DEBUG: finalizou em addCategoria. Categoria: ${categoria}');
    }
  }

  Future<CategoriaModel?> getCategoriaByDescricao(String descricao) async {
    // Reutilizando a extensão IterableExtension<T> que já está no seu projeto
    return _categoriasBox.values.firstWhereOrNull(
      (c) =>
          c.descricao.toLowerCase() == descricao.toLowerCase() &&
          c.isActive &&
          !c.isRemoved,
    );
  }

  Future<void> updateCategoria(CategoriaModel categoria) async {
    final existingCategoria = _categoriasBox.get(categoria.id);
    if (existingCategoria != null) {
      existingCategoria.descricao = categoria.descricao;
      existingCategoria.isActive = categoria.isActive;
      existingCategoria.isRemoved = categoria.isRemoved;
      await existingCategoria.save();
    } else {
      await _categoriasBox.put(categoria.id, categoria);
    }
  }

  Future<void> deleteCategoria(String id) async {
    await _categoriasBox.delete(id);
  }
}
