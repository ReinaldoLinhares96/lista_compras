import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/orcamento_model.dart';
import '../../core/constants/firestore_collections.dart';

class OrcamentoRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Usaremos um ID fixo para o documento de orçamento, já que é um singleton por usuário no MVP
  static const String orcamentoDocId = 'user_budget';

  // Inicializa um orçamento padrão se não existir (ex: 0.0)
  Future<void> initializeDefaultOrcamento() async {
    final doc = await _firestore
        .collection(FirestoreCollections.orcamentos)
        .doc(orcamentoDocId)
        .get();
    if (!doc.exists) {
      final defaultOrcamento = OrcamentoModel(
        id: orcamentoDocId,
        valorMaximo: 0.0, // Orçamento inicial pode ser zero
        updatedAt: DateTime.now(),
      );
      await _firestore
          .collection(FirestoreCollections.orcamentos)
          .doc(orcamentoDocId)
          .set(defaultOrcamento.toFirestore());
      if (kDebugMode) {
        print('Orçamento padrão inicializado com R\$0.00');
      }
    }
  }

  // Obtém o orçamento atual
  Stream<OrcamentoModel> getOrcamento() {
    return _firestore
        .collection(FirestoreCollections.orcamentos)
        .doc(orcamentoDocId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists || snapshot.data() == null) {
            // Retorna um modelo padrão se não existir para evitar erros no StreamBuilder
            return OrcamentoModel(
              id: orcamentoDocId,
              valorMaximo: 0.0,
              updatedAt: DateTime.now(),
            );
          }
          return OrcamentoModel.fromFirestore(snapshot);
        });
  }

  // Atualiza o orçamento
  Future<void> updateOrcamento(double novoValor) async {
    await _firestore
        .collection(FirestoreCollections.orcamentos)
        .doc(orcamentoDocId)
        .update({
          'valorMaximo': novoValor,
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }
}
