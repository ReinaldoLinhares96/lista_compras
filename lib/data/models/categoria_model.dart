import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'categoria_model.g.dart';

@HiveType(typeId: 2)
class CategoriaModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String descricao;
  @HiveField(2) // NOVO CAMPO
  bool isActive;
  @HiveField(3) // NOVO CAMPO
  bool isRemoved;
  @HiveField(4)
  String? userId;

  CategoriaModel({
    String? id,
    required this.descricao,
    this.isActive = true, // NOVO PARÂMETRO
    this.isRemoved = false, // NOVO PARÂMETRO
    this.userId,
  }) : id = id ?? const Uuid().v4();

  CategoriaModel copyWith({
    String? id,
    String? descricao,
    bool? isActive, // NOVO PARÂMETRO
    bool? isRemoved, // NOVO PARÂMETRO
    String? userId,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      isActive: isActive ?? this.isActive, // NOVO NO COPYWITH
      isRemoved: isRemoved ?? this.isRemoved, // NOVO NO COPYWITH
      userId: userId ?? this.userId,
    );
  }

  // NOVO: Factory constructor para ler do Firestore
  factory CategoriaModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('missing data for CategoriaModel(id: ${doc.id})');
    }
    return CategoriaModel(
      id: doc.id,
      descricao: data['descricao'] as String,
      isActive: data['isActive'] as bool? ?? true,
      isRemoved: data['isRemoved'] as bool? ?? false,
      userId: data['userId'] as String?,
    );
  }

  // NOVO: Método para converter para um Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'descricao': descricao,
      'isActive': isActive,
      'isRemoved': isRemoved,
      'userId': userId,
    };
  }
}
