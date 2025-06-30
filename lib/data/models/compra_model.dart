import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
// ignore: unused_import
import '../../core/enums/compra_status_type.dart';

class CompraModel {
  final String id;
  final DateTime dataHoraInicio;
  final DateTime? dataHoraFim; // Pode ser nulo se a compra estiver ativa
  final double valorTotalCalculado;
  final String compraStatusId; // Referencia o ID da CompraStatusModel
  final bool isActive;
  final bool isRemoved;
  final DateTime createdAt;
  final DateTime updatedAt;

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
  })  : id = id ?? const Uuid().v4(),
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
  }) {
    return CompraModel(
      id: id ?? this.id,
      dataHoraInicio: dataHoraInicio ?? this.dataHoraInicio,
      dataHoraFim: dataHoraFim ?? this.dataHoraFim,
      valorTotalCalculado: valorTotalCalculado ?? this.valorTotalCalculado,
      compraStatusId: compraStatusId ?? this.compraStatusId,
      isActive: isActive ?? this.isActive,
      isRemoved: isRemoved ?? this.isRemoved,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CompraModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompraModel(
      id: doc.id,
      dataHoraInicio: (data['dataHoraInicio'] as Timestamp).toDate(),
      dataHoraFim: (data['dataHoraFim'] as Timestamp?)?.toDate(),
      valorTotalCalculado: (data['valorTotalCalculado'] as num? ?? 0.0).toDouble(),
      compraStatusId: data['compraStatusId'] as String,
      isActive: data['isActive'] as bool? ?? true,
      isRemoved: data['isRemoved'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'dataHoraInicio': Timestamp.fromDate(dataHoraInicio),
      'dataHoraFim': dataHoraFim != null ? Timestamp.fromDate(dataHoraFim!) : null,
      'valorTotalCalculado': valorTotalCalculado,
      'compraStatusId': compraStatusId,
      'isActive': isActive,
      'isRemoved': isRemoved,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}