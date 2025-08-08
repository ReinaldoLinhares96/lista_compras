// ignore_for_file: depend_on_referenced_packages

import 'package:hive_flutter/hive_flutter.dart';
import '../models/orcamento_model.dart';
import 'package:rxdart/rxdart.dart';

class OrcamentoRepository {
  late Box<double> _orcamentoBox;

  static const String _orcamentoKey = 'valorMaximoOrcamento';

  OrcamentoRepository() {
    _orcamentoBox = Hive.box<double>('orcamentoBox');
  }

  Future<void> initializeDefaultOrcamento() async {
    if (!_orcamentoBox.containsKey(_orcamentoKey)) {
      await _orcamentoBox.put(_orcamentoKey, 0.0);
    }
  }

  Stream<OrcamentoModel> getOrcamento() {
    return _orcamentoBox
        .watch(key: _orcamentoKey)
        .map((event) {
          final double valor = _orcamentoBox.get(_orcamentoKey) ?? 0.0;
          return OrcamentoModel(
            id: _orcamentoKey,
            valorMaximo: valor,
            updatedAt: DateTime.now(),
          );
        })
        .startWith(
          OrcamentoModel(
            id: _orcamentoKey,
            valorMaximo: _orcamentoBox.get(_orcamentoKey) ?? 0.0,
            updatedAt: DateTime.now(),
          ),
        );
  }

  Future<void> updateOrcamento(double novoValor) async {
    await _orcamentoBox.put(_orcamentoKey, novoValor);
  }
}
