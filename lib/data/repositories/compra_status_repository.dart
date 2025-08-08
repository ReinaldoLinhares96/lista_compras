// ignore_for_file: depend_on_referenced_packages, avoid_print, unnecessary_brace_in_string_interps

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
          isActive: true,
          isRemoved: false,
        );
        await _compraStatusBox.put(docId, newStatus);
      }
    }
  }

  Stream<List<CompraStatusModel>> getCompraStatus() {
    return _compraStatusBox
        .watch()
        .map(
          (event) => _compraStatusBox.values
              .where((s) => s.isActive && !s.isRemoved)
              .toList(),
        )
        .startWith(
          _compraStatusBox.values
              .where((s) => s.isActive && !s.isRemoved)
              .toList(),
        );
  }

  CompraStatusModel? getStatusById(String id) {
    return _compraStatusBox.get(id);
  }

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
