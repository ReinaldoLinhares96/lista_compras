import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Para gerar IDs únicos

class CategoriaModel {
  final String id;
  final String descricao;

  CategoriaModel({
    String? id, // Opcional para novos
    required this.descricao,
  }) : id = id ?? const Uuid().v4(); // Gera um UUID se nenhum ID for fornecido

  factory CategoriaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoriaModel(id: doc.id, descricao: data['descricao'] as String);
  }

  Map<String, dynamic> toFirestore() {
    return {'descricao': descricao};
  }
}
