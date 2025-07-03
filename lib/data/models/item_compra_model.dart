import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ItemCompraModel {
  final String id;
  final String compraId;
  final String? produtoId; // Nulo se for item avulso
  final String nomeProduto;
  final double quantidadeComprada;
  final double precoUnitario;
  final double subtotal; // Este será o resultado do cálculo
  final bool ehAvulso;
  final bool adicionadoNaLista; // Nome correto da propriedade
  final DateTime createdAt;
  final DateTime updatedAt;

  ItemCompraModel({
    String? id,
    required this.compraId,
    this.produtoId,
    required this.nomeProduto,
    required this.quantidadeComprada,
    required this.precoUnitario,
    double? subtotal,
    this.ehAvulso = false,
    this.adicionadoNaLista = false, // Nome correto da propriedade no construtor
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       subtotal = subtotal ?? (quantidadeComprada * precoUnitario),
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
    bool? adicionadoNaLista, // Nome correto da propriedade no copyWith
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final newQuantidadeComprada = quantidadeComprada ?? this.quantidadeComprada;
    final newPrecoUnitario = precoUnitario ?? this.precoUnitario;
    final calculatedSubtotal = newQuantidadeComprada * newPrecoUnitario;

    return ItemCompraModel(
      id: id ?? this.id,
      compraId: compraId ?? this.compraId,
      produtoId: produtoId ?? this.produtoId,
      nomeProduto: nomeProduto ?? this.nomeProduto,
      quantidadeComprada: newQuantidadeComprada,
      precoUnitario: newPrecoUnitario,
      subtotal: subtotal ?? calculatedSubtotal,
      ehAvulso: ehAvulso ?? this.ehAvulso,
      adicionadoNaLista:
          adicionadoNaLista ?? this.adicionadoNaLista, // CORRIGIDO AQUI!
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
      subtotal: (data['subtotal'] as num? ?? 0.0).toDouble(),
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
