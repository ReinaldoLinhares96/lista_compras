import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'produto_model.g.dart';

@HiveType(typeId: 0)
class ProdutoModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String nome;
  @HiveField(2)
  int quantidadeIdealMes;
  @HiveField(3)
  final String categoriaId;
  @HiveField(4)
  int quantidadeEmEstoque;
  @HiveField(5)
  bool isActive;
  @HiveField(6)
  bool isRemoved;
  @HiveField(7)
  DateTime createdAt;
  @HiveField(8)
  DateTime updatedAt;

  ProdutoModel({
    String? id,
    required this.nome,
    required this.quantidadeIdealMes,
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
    int? quantidadeIdealMes,
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
