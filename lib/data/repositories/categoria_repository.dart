// ignore_for_file: unnecessary_brace_in_string_interps

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/categoria_model.dart';
import '../../core/constants/firestore_collections.dart';
import '../../core/enums/categoria_type.dart';

class CategoriaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Adiciona as categorias padrão se não existirem
  Future<void> initializeDefaultCategorias() async {
    final CollectionReference collection = _firestore.collection(FirestoreCollections.categorias);

    for (var type in CategoriaType.values) {
      final docId = type.value.toString(); // Usar o valor do enum como ID do documento
      final doc = await collection.doc(docId).get();

      if (!doc.exists) {
        String description;
        switch (type) {
          case CategoriaType.alimentos:
            description = 'Alimentos';
            break;
          case CategoriaType.higienePessoal:
            description = 'Higiene Pessoal';
            break;
          case CategoriaType.limpezaDomestica:
            description = 'Limpeza Doméstica';
            break;
        }
        final newCategoria = CategoriaModel(
          id: docId,
          categoriaType: type,
          descricao: description,
        );
        await collection.doc(docId).set(newCategoria.toFirestore());
        if (kDebugMode) {
          print('Categoria padrão "${description}" adicionada.');
        }
      }
    }
  }

  // Obtém todas as categorias
  Stream<List<CategoriaModel>> getCategorias() {
    return _firestore
        .collection(FirestoreCollections.categorias)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoriaModel.fromFirestore(doc))
            .toList());
  }
}