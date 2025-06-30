import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/categoria_type.dart';

class CategoriaModel {
  final String id;
  final CategoriaType categoriaType;
  final String descricao;

  CategoriaModel({
    required this.id,
    required this.categoriaType,
    required this.descricao,
  });

  factory CategoriaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoriaModel(
      id: doc.id,
      categoriaType: CategoriaTypeExtension.fromValue(data['categoriaType'] as int),
      descricao: data['descricao'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'categoriaType': categoriaType.value,
      'descricao': descricao,
    };
  }
}