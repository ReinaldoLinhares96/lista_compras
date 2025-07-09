// ignore_for_file: cast_from_null_always_fails, depend_on_referenced_packages

import 'package:hive_flutter/hive_flutter.dart';
import 'package:lista_compras/presentation/pages/active_shopping_page.dart';
import '../models/unidade_medida_model.dart';
import 'package:rxdart/rxdart.dart';

class UnidadeMedidaRepository {
  late Box<UnidadeMedidaModel> _unidadesBox;

  UnidadeMedidaRepository() {
    _unidadesBox = Hive.box<UnidadeMedidaModel>('unidadesMedidaBox');
  }

  Stream<List<UnidadeMedidaModel>> getUnidadesMedida() {
    // Filtrar apenas unidades ativas
    return _unidadesBox
        .watch()
        .map((event) {
          final allUnidades = _unidadesBox.values
              .where((u) => u.isActive && !u.isRemoved)
              .toList(); // FILTRO AQUI
          allUnidades.sort(
            (a, b) =>
                a.descricao.toLowerCase().compareTo(b.descricao.toLowerCase()),
          );
          return allUnidades;
        })
        .startWith(
          _unidadesBox.values.where((u) => u.isActive && !u.isRemoved).toList(),
        ); // Emissão inicial filtrada
  }

  Future<void> addUnidade(UnidadeMedidaModel unidade) async {
    await _unidadesBox.put(unidade.id, unidade);
  }

  Future<UnidadeMedidaModel?> getUnidadeByDescricaoAndSimbolo(
    String descricao,
    String simbolo,
  ) async {
    return _unidadesBox.values.firstWhereOrNull(
      (u) =>
          u.descricao.toLowerCase() == descricao.toLowerCase() &&
          u.simbolo.toLowerCase() == simbolo.toLowerCase() &&
          u.isActive &&
          !u.isRemoved,
    );
  }

  Future<void> updateUnidade(UnidadeMedidaModel unidade) async {
    // Quando você usa .put() com um HiveObject, ele sobrescreve.
    // O ideal é pegar o objeto, alterar as propriedades e chamar .save()
    final existingUnidade = _unidadesBox.get(unidade.id);
    if (existingUnidade != null) {
      existingUnidade.descricao = unidade.descricao;
      existingUnidade.simbolo = unidade.simbolo;
      existingUnidade.isActive = unidade.isActive;
      existingUnidade.isRemoved = unidade.isRemoved;
      await existingUnidade.save();
    } else {
      // Se não existe, adicione
      await _unidadesBox.put(unidade.id, unidade);
    }
  }

  // AGORA É REMOÇÃO LÓGICA
  Future<void> deleteUnidade(String id) async {
    await _unidadesBox.delete(id);
  }
}
