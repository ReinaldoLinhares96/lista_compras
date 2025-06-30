import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/enums/compra_status_type.dart';

class CompraStatusModel {
  final String id;
  final CompraStatusType compraStatusType;
  final String descricao;

  CompraStatusModel({
    required this.id,
    required this.compraStatusType,
    required this.descricao,
  });

  factory CompraStatusModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompraStatusModel(
      id: doc.id,
      compraStatusType: CompraStatusTypeExtension.fromValue(data['compraStatusType'] as int),
      descricao: data['descricao'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'compraStatusType': compraStatusType.value,
      'descricao': descricao,
    };
  }
}