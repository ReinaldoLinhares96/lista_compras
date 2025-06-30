// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/unidade_medida_model.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/enums/unidade_medida_type.dart';

class UnidadeMedidaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Adiciona as unidades de medida padrão se não existirem
  Future<void> initializeDefaultUnidadesMedida() async {
    final CollectionReference collection = _firestore.collection(FirestoreCollections.unidadesMedida);

    for (var type in UnidadeMedidaType.values) {
      final docId = type.value.toString(); // Usar o valor do enum como ID do documento
      final doc = await collection.doc(docId).get();

      if (!doc.exists) {
        // Se o documento não existe, cria-o
        String description;
        switch (type) {
          case UnidadeMedidaType.unidade:
            description = 'Unidade';
            break;
          case UnidadeMedidaType.quilograma:
            description = 'Quilograma';
            break;
          case UnidadeMedidaType.litro:
            description = 'Litro';
            break;
        }
        final newUnidade = UnidadeMedidaModel(
          id: docId,
          unidadeMedidaType: type,
          descricao: description,
        );
        await collection.doc(docId).set(newUnidade.toFirestore());
        if (kDebugMode) {
          print('Unidade de Medida padrão "${description}" adicionada.');
        }
      }
    }
  }

  // Obtém todas as unidades de medida
  Stream<List<UnidadeMedidaModel>> getUnidadesMedida() {
    return _firestore
        .collection(FirestoreCollections.unidadesMedida)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UnidadeMedidaModel.fromFirestore(doc))
            .toList());
  }
}