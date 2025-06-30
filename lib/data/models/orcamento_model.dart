import 'package:cloud_firestore/cloud_firestore.dart';

class OrcamentoModel {
  final String id;
  final double valorMaximo;
  final DateTime updatedAt;

  OrcamentoModel({
    required this.id,
    required this.valorMaximo,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  OrcamentoModel copyWith({
    String? id,
    double? valorMaximo,
    DateTime? updatedAt,
  }) {
    return OrcamentoModel(
      id: id ?? this.id,
      valorMaximo: valorMaximo ?? this.valorMaximo,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory OrcamentoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrcamentoModel(
      id: doc.id,
      valorMaximo: (data['valorMaximo'] as num).toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'valorMaximo': valorMaximo,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}