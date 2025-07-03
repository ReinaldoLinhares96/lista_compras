// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/unidade_medida_model.dart';
import '../../core/constants/firestore_collections.dart';

class UnidadeMedidaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _unidadesCollection = FirebaseFirestore.instance
      .collection(FirestoreCollections.unidadesMedida);

  // Obtém todas as unidades de medida
  Stream<List<UnidadeMedidaModel>> getUnidadesMedida() {
    return _unidadesCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => UnidadeMedidaModel.fromFirestore(doc))
          .toList(),
    );
  }

  // MÉTODO addUnidade ATUALIZADO
  Future<void> addUnidade(UnidadeMedidaModel unidade) async {
    // Se o ID for gerado no modelo (UUID), usamos set. Se for algo específico, usamos .doc(unidade.id).set()
    // Para unidades criadas pelo usuário, um UUID gerado pelo modelo é ideal.
    await _unidadesCollection.doc(unidade.id).set(unidade.toFirestore());
  }

  // NOVO MÉTODO PARA BUSCAR POR DESCRIÇÃO/SÍMBOLO (para validação de duplicidade)
  Future<UnidadeMedidaModel?> getUnidadeByDescricaoAndSimbolo(
    String descricao,
    String simbolo,
  ) async {
    final querySnapshot = await _unidadesCollection
        .where('descricao', isEqualTo: descricao)
        .where('simbolo', isEqualTo: simbolo)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return UnidadeMedidaModel.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  // NOVO: Método para atualizar uma unidade de medida existente
  Future<void> updateUnidade(UnidadeMedidaModel unidade) async {
    await _unidadesCollection.doc(unidade.id).update(unidade.toFirestore());
  }

  // NOVO: Método para deletar uma unidade de medida
  Future<void> deleteUnidade(String id) async {
    await _unidadesCollection.doc(id).delete();
  }
}
