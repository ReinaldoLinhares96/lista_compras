import 'package:hive/hive.dart'; // Importe o Hive
import 'package:uuid/uuid.dart';

part 'produto_model.g.dart'; // Esta linha será gerada pelo hive_generator

@HiveType(typeId: 0) // typeId deve ser único para cada modelo
class ProdutoModel extends HiveObject {
  // Estenda HiveObject
  @HiveField(0) // Campo do Hive
  final String id;
  @HiveField(1)
  final String nome;
  @HiveField(2)
  int quantidadeIdealMes; // CORREÇÃO AQUI: REMOVIDO 'final'
  @HiveField(3)
  final String categoriaId;
  @HiveField(4)
  int quantidadeEmEstoque; // Não é final, pode ser alterado
  @HiveField(5)
  bool isActive; // Não é final
  @HiveField(6)
  bool isRemoved; // Não é final
  @HiveField(7)
  DateTime createdAt; // Não é final
  @HiveField(8)
  DateTime updatedAt; // Não é final

  ProdutoModel({
    String? id,
    required this.nome,
    required this.quantidadeIdealMes, // Este ainda é um parâmetro required no construtor
    required this.categoriaId,
    this.quantidadeEmEstoque = 0,
    this.isActive = true,
    this.isRemoved = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  ProdutoModel copyWith({
    String? id,
    String? nome,
    int?
    quantidadeIdealMes, // Ainda pode ser usado no copyWith para criar uma nova instância
    String? categoriaId,
    int? quantidadeEmEstoque,
    bool? isActive,
    bool? isRemoved,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProdutoModel(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      quantidadeIdealMes: quantidadeIdealMes ?? this.quantidadeIdealMes,
      categoriaId: categoriaId ?? this.categoriaId,
      quantidadeEmEstoque: quantidadeEmEstoque ?? this.quantidadeEmEstoque,
      isActive: isActive ?? this.isActive,
      isRemoved: isRemoved ?? this.isRemoved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Métodos fromFirestore/toFirestore não são mais necessários para Hive
}
