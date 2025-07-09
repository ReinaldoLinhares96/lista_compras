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
    );
  }
}
