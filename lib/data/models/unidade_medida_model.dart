import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/unidade_medida_type.dart';

class UnidadeMedidaModel {
  final String id;
  final UnidadeMedidaType unidadeMedidaType;
  final String descricao;

  UnidadeMedidaModel({
    required this.id,
    required this.unidadeMedidaType,
    required this.descricao,
  });

  // Converte um DocumentSnapshot do Firestore para um objeto UnidadeMedidaModel
  factory UnidadeMedidaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UnidadeMedidaModel(
      id: doc.id,
      unidadeMedidaType: UnidadeMedidaTypeExtension.fromValue(data['unidadeMedidaType'] as int),
      descricao: data['descricao'] as String,
    );
  }

  // Converte um objeto UnidadeMedidaModel para um Map para ser salvo no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'unidadeMedidaType': unidadeMedidaType.value,
      'descricao': descricao,
    };
  }
}