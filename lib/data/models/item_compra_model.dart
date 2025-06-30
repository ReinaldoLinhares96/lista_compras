import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ItemCompraModel {
  final String id;
  final String compraId;
  final String? produtoId; // Nulo se for item avulso
  final String nomeProduto;
  final double quantidadeComprada;
  final double precoUnitario;
  final double subtotal;
  final bool ehAvulso;
  final bool adicionadoNaLista;
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemCompraModel({
    String? id,
    required this.compraId,
    this.produtoId,
    required this.nomeProduto,
    required this.quantidadeComprada,
    required this.precoUnitario,
    this.subtotal = 0.0, // Será calculado
    this.ehAvulso = false,
    this.adicionadoNaLista = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),   
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  ItemCompraModel copyWith({
    String? id,
    String? compraId,
    String? produtoId,
    String? nomeProduto,
    double? quantidadeComprada,
    double? precoUnitario,
    double? subtotal,
    bool? ehAvulso,
    bool? adicionadoNaLista,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemCompraModel(
      id: id ?? this.id,
      compraId: compraId ?? this.compraId,
      produtoId: produtoId ?? this.produtoId,
      nomeProduto: nomeProduto ?? this.nomeProduto,
      quantidadeComprada: quantidadeComprada ?? this.quantidadeComprada,
      precoUnitario: precoUnitario ?? this.precoUnitario,
      subtotal: subtotal ?? (quantidadeComprada ?? this.quantidadeComprada) * (precoUnitario ?? this.precoUnitario),
      ehAvulso: ehAvulso ?? this.ehAvulso,
      adicionadoNaLista: adicionadoNaLista ?? this.adicionadoNaLista,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ItemCompraModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemCompraModel(
      id: doc.id,
      compraId: data['compraId'] as String,
      produtoId: data['produtoId'] as String?,
      nomeProduto: data['nomeProduto'] as String,
      quantidadeComprada: (data['quantidadeComprada'] as num).toDouble(),
      precoUnitario: (data['precoUnitario'] as num).toDouble(),
      subtotal: (data['subtotal'] as num? ?? 0.0).toDouble(), // Garante que o subtotal exista
      ehAvulso: data['ehAvulso'] as bool? ?? false,
      adicionadoNaLista: data['adicionadoNaLista'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'compraId': compraId,
      'produtoId': produtoId,
      'nomeProduto': nomeProduto,
      'quantidadeComprada': quantidadeComprada,
      'precoUnitario': precoUnitario,
      'subtotal': subtotal,
      'ehAvulso': ehAvulso,
      'adicionadoNaLista': adicionadoNaLista,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}