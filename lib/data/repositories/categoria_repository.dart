// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/categoria_model.dart';
import '../../core/constants/firestore_collections.dart';

class CategoriaRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference _categoriasCollection = FirebaseFirestore.instance
      .collection(FirestoreCollections.categorias);

  // Obtém todas as categorias
  Stream<List<CategoriaModel>> getCategorias() {
    return _categoriasCollection.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => CategoriaModel.fromFirestore(doc))
          .toList(),
    );
  }

  // MÉTODO addCategoria ATUALIZADO
  Future<void> addCategoria(CategoriaModel categoria) async {
    // Se o ID for gerado no modelo (UUID), usamos set.
    await _categoriasCollection.doc(categoria.id).set(categoria.toFirestore());
  }

  // NOVO MÉTODO PARA BUSCAR POR DESCRIÇÃO (para validação de duplicidade)
  Future<CategoriaModel?> getCategoriaByDescricao(String descricao) async {
    final querySnapshot = await _categoriasCollection
        .where('descricao', isEqualTo: descricao)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return CategoriaModel.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  // NOVO: Método para atualizar uma categoria existente
  Future<void> updateCategoria(CategoriaModel categoria) async {
    await _categoriasCollection
        .doc(categoria.id)
        .update(categoria.toFirestore());
  }

  // NOVO: Método para deletar uma categoria
  Future<void> deleteCategoria(String id) async {
    await _categoriasCollection.doc(id).delete();
  }
}
