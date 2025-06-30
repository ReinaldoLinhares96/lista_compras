// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/compra_status_model.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/enums/compra_status_type.dart';

class CompraStatusRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Adiciona os status de compra padrão se não existirem
  Future<void> initializeDefaultCompraStatus() async {
    final CollectionReference collection = _firestore.collection(FirestoreCollections.comprasStatus);

    for (var type in CompraStatusType.values) {
      final docId = type.value.toString(); // Usar o valor do enum como ID do documento
      final doc = await collection.doc(docId).get();

      if (!doc.exists) {
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
          compraStatusType: type,
          descricao: description,
        );
        await collection.doc(docId).set(newStatus.toFirestore());
        if (kDebugMode) {
          print('Status de Compra padrão "${description}" adicionado.');
        }
      }
    }
  }

  // Obtém todos os status de compra
  Stream<List<CompraStatusModel>> getCompraStatus() {
    return _firestore
        .collection(FirestoreCollections.comprasStatus)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CompraStatusModel.fromFirestore(doc))
            .toList());
  }
}