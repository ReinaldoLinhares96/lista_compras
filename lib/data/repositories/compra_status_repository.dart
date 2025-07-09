// ignore_for_file: depend_on_referenced_packages, avoid_print, unnecessary_brace_in_string_interps

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/compra_status_model.dart';
import '../../core/enums/compra_status_type.dart';
import 'package:rxdart/rxdart.dart';

class CompraStatusRepository {
  late Box<CompraStatusModel> _compraStatusBox;

  CompraStatusRepository() {
    _compraStatusBox = Hive.box<CompraStatusModel>('compraStatusBox');
  }

  Future<void> initializeDefaultCompraStatus() async {
    for (var type in CompraStatusType.values) {
      final String docId = type.value.toString();

      final existingStatus = _compraStatusBox.get(docId);

      if (existingStatus == null) {
        String description;
        switch (type) {
          case CompraStatusType.ativa:
            description = 'Ativa';
            break;
          case CompraStatusType.finalizada:
            description = 'Finalizada';
            break;
          case CompraStatusType.cancelada:
            description = 'Cancelada';
            break;
        }
        final newStatus = CompraStatusModel(
          id: docId,
          descricao: description,
          isActive: true, // NOVO: Definir como ativo por padrão
          isRemoved: false, // NOVO: Definir como não removido por padrão
        );
        await _compraStatusBox.put(docId, newStatus);
        if (kDebugMode) {
          print('Status de Compra padrão "${description}" adicionado ao Hive.');
        }
      }
    }
  }

  Stream<List<CompraStatusModel>> getCompraStatus() {
    // Filtrar apenas status ativos (se houver a necessidade de desativar um status)
    return _compraStatusBox
        .watch()
        .map(
          (event) => _compraStatusBox.values
              .where((s) => s.isActive && !s.isRemoved)
              .toList(),
        ) // FILTRO AQUI
        .startWith(
          _compraStatusBox.values
              .where((s) => s.isActive && !s.isRemoved)
              .toList(),
        ); // Emissão inicial
  }

  CompraStatusModel? getStatusById(String id) {
    return _compraStatusBox.get(
      id,
    ); // Não precisa filtrar por isActive aqui, pois o ID é único
  }

  // Adicionar métodos update e delete para CompraStatusModel se precisar gerenciar no futuro
  Future<void> updateCompraStatus(CompraStatusModel status) async {
    final existingStatus = _compraStatusBox.get(status.id);
    if (existingStatus != null) {
      existingStatus.descricao = status.descricao;
      existingStatus.isActive = status.isActive;
      existingStatus.isRemoved = status.isRemoved;
      await existingStatus.save();
    } else {
      await _compraStatusBox.put(status.id, status);
    }
  }

  Future<void> deleteCompraStatus(String id) async {
    final status = _compraStatusBox.get(id);
    if (status != null) {
      status.isActive = false;
      status.isRemoved = true;
      await status.save();
    }
  }
}
