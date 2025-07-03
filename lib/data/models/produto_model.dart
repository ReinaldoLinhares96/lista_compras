// ignore_for_file: unused_import

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart'; // Para gerar IDs

class ProdutoModel {
  final String id;
  final String nome;
  final double quantidadeIdealMes;
  final String unidadeMedidaId; // Referencia o ID da UnidadeMedidaModel
  final String categoriaId; // Referencia o ID da CategoriaModel
  final double quantidadeEmEstoque;
  final bool isActive;
  final bool isRemoved;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProdutoModel({
    String? id, // Opcional no construtor para novos produtos
    required this.nome,
    required this.quantidadeIdealMes,
    required this.unidadeMedidaId,
    required this.categoriaId,
    this.quantidadeEmEstoque = 0.0, // Valor padrão
    this.isActive = true,
    this.isRemoved = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(), // Gera um UUID se nenhum ID for fornecido
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  // Cria uma cópia do ProdutoModel com novos valores (útil para atualizações)
  ProdutoModel copyWith({
    String? id,
    String? nome,
    double? quantidadeIdealMes,
    String? unidadeMedidaId,
    String? categoriaId,
    double? quantidadeEmEstoque,
    bool? isActive,
    bool? isRemoved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProdutoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      quantidadeIdealMes: quantidadeIdealMes ?? this.quantidadeIdealMes,
      unidadeMedidaId: unidadeMedidaId ?? this.unidadeMedidaId,
      categoriaId: categoriaId ?? this.categoriaId,
      quantidadeEmEstoque: quantidadeEmEstoque ?? this.quantidadeEmEstoque,
      isActive: isActive ?? this.isActive,
      isRemoved: isRemoved ?? this.isRemoved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Converte um DocumentSnapshot do Firestore para um objeto ProdutoModel
  factory ProdutoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProdutoModel(
      id: doc.id,
      nome: data['nome'] as String,
      quantidadeIdealMes: (data['quantidadeIdealMes'] as num).toDouble(),
      unidadeMedidaId: data['unidadeMedidaId'] as String,
      categoriaId: data['categoriaId'] as String,
      quantidadeEmEstoque: (data['quantidadeEmEstoque'] as num? ?? 0.0)
          .toDouble(), // Null-safe
      isActive: data['isActive'] as bool? ?? true,
      isRemoved: data['isRemoved'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Converte um objeto ProdutoModel para um Map para ser salvo no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'quantidadeIdealMes': quantidadeIdealMes,
      'unidadeMedidaId': unidadeMedidaId,
      'categoriaId': categoriaId,
      'quantidadeEmEstoque': quantidadeEmEstoque,
      'isActive': isActive,
      'isRemoved': isRemoved,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
