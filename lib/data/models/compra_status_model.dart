import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'compra_status_model.g.dart';

@HiveType(typeId: 5)
class CompraStatusModel extends HiveObject {
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

  CompraStatusModel({
    required this.id,
    required this.descricao,
    this.isActive = true, // NOVO PARÂMETRO
    this.isRemoved = false, // NOVO PARÂMETRO
    this.userId,
  });

  CompraStatusModel copyWith({
    // Adicionado copyWith para este modelo
    String? id,
    String? descricao,
    bool? isActive,
    bool? isRemoved,
    String? userId,
  }) {
    return CompraStatusModel(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      isActive: isActive ?? this.isActive,
      isRemoved: isRemoved ?? this.isRemoved,
      userId: userId ?? this.userId,
    );
  }

  // NOVO: Factory constructor para ler do Firestore
  factory CompraStatusModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('missing data for CompraStatusModel(id: ${doc.id})');
    }
    return CompraStatusModel(
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
