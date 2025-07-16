import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'compra_model.g.dart'; // Será gerado

@HiveType(typeId: 3) // typeId único
class CompraModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime dataHoraInicio;
  @HiveField(2)
  DateTime? dataHoraFim; // Não é final, pode ser alterado
  @HiveField(3)
  double valorTotalCalculado; // Não é final, pode ser alterado
  @HiveField(4)
  String compraStatusId; // CORREÇÃO AQUI: REMOVIDO 'final'
  @HiveField(5)
  bool isActive; // Não é final, pode ser alterado
  @HiveField(6)
  bool isRemoved; // Não é final, pode ser alterado
  @HiveField(7)
  DateTime createdAt; // Não é final, pode ser alterado
  @HiveField(8)
  DateTime updatedAt; // Não é final, pode ser alterado
  @HiveField(9)
  String? userId;

  CompraModel({
    String? id,
    required this.dataHoraInicio,
    this.dataHoraFim,
    this.valorTotalCalculado = 0.0,
    required this.compraStatusId,
    this.isActive = true,
    this.isRemoved = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.userId,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  CompraModel copyWith({
    String? id,
    DateTime? dataHoraInicio,
    DateTime? dataHoraFim,
    double? valorTotalCalculado,
    String? compraStatusId,
    bool? isActive,
    bool? isRemoved,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    // Usamos o construtor, que espera um valor para compraStatusId.
    // Garantimos que ele não é nulo.
    return CompraModel(
      id: id ?? this.id,
      dataHoraInicio: dataHoraInicio ?? this.dataHoraInicio,
      dataHoraFim: dataHoraFim ?? this.dataHoraFim,
      valorTotalCalculado: valorTotalCalculado ?? this.valorTotalCalculado,
      compraStatusId:
          compraStatusId ??
          this.compraStatusId, // Passa o valor existente ou novo
      isActive: isActive ?? this.isActive,
      isRemoved: isRemoved ?? this.isRemoved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  // NOVO: Factory constructor para ler do Firestore
  factory CompraModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw StateError('missing data for CompraModel(id: ${doc.id})');
    }
    return CompraModel(
      id: doc.id,
      dataHoraInicio: (data['dataHoraInicio'] as Timestamp).toDate(),
      dataHoraFim: (data['dataHoraFim'] as Timestamp?)?.toDate(),
      valorTotalCalculado: (data['valorTotalCalculado'] as num? ?? 0.0)
          .toDouble(),
      compraStatusId: data['compraStatusId'] as String,
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
      'dataHoraInicio': Timestamp.fromDate(dataHoraInicio),
      'dataHoraFim': dataHoraFim != null
          ? Timestamp.fromDate(dataHoraFim!)
          : null,
      'valorTotalCalculado': valorTotalCalculado,
      'compraStatusId': compraStatusId,
      'isActive': isActive,
      'isRemoved': isRemoved,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'userId': userId,
    };
  }
}
