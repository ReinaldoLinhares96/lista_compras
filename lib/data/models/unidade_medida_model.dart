import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Para gerar IDs únicos

class UnidadeMedidaModel {
  final String id;
  final String descricao;
  final String simbolo; // NOVO CAMPO

  UnidadeMedidaModel({
    String? id,
    required this.descricao,
    required this.simbolo,
  }) : id = id ?? const Uuid().v4();

  // Converte um DocumentSnapshot do Firestore para um objeto UnidadeMedidaModel
  factory UnidadeMedidaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UnidadeMedidaModel(
      id: doc.id,
      descricao: data['descricao'] as String,
      simbolo: data['simbolo'] as String,
    );
  }

  // Converte um objeto UnidadeMedidaModel para um Map para ser salvo no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'descricao': descricao,
      'simbolo': simbolo, // SALVAR O NOVO CAMPO
    };
  }
}
