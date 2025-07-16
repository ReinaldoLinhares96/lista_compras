import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart'; // Importe o Hive
import 'package:uuid/uuid.dart';

part 'produto_model.g.dart'; // Esta linha será gerada pelo hive_generator

@HiveType(typeId: 0) // typeId deve ser único para cada modelo
class ProdutoModel extends HiveObject {
  // Estenda HiveObject
  @HiveField(0) // Campo do Hive
  final String id;
  @HiveField(1)
  String nome;
  @HiveField(2)
  int quantidadeIdealMes; // CORREÇÃO AQUI: REMOVIDO 'final'
  @HiveField(3)
  String categoriaId;
  @HiveField(4)
  int quantidadeEmEstoque; // Não é final, pode ser alterado
  @HiveField(5)
  bool isActive; // Não é final
  @HiveField(6)
  bool isRemoved; // Não é final
  @HiveField(7)
  DateTime createdAt; // Não é final
  @HiveField(8)
  DateTime updatedAt;
  @HiveField(9)
  String? userId;

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
    this.userId,
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
    String? userId,
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
      userId: userId ?? this.userId,
    );
  }

  // Métodos fromFirestore/toFirestore

  // NOVO: Factory constructor para ler do Firestore
  factory ProdutoModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Pode ser nulo
    if (data == null) {
      throw StateError('missing data for ProdutoModel(id: ${doc.id})');
    }
    return ProdutoModel(
      id: doc.id,
      nome: data['nome'] as String,
      quantidadeIdealMes: (data['quantidadeIdealMes'] as num).toInt(),
      categoriaId: data['categoriaId'] as String,
      quantidadeEmEstoque: (data['quantidadeEmEstoque'] as num? ?? 0).toInt(),
      isActive: data['isActive'] as bool? ?? true,
      isRemoved: data['isRemoved'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      userId: data['userId'] as String?,
    );
  }

  // NOVO: Método para converter para um Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nome': nome,
      'quantidadeIdealMes': quantidadeIdealMes,
      'categoriaId': categoriaId,
      'quantidadeEmEstoque': quantidadeEmEstoque,
      'isActive': isActive,
      'isRemoved': isRemoved,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }
}
