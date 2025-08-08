import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'compra_model.g.dart';

@HiveType(typeId: 3)
class CompraModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final DateTime dataHoraInicio;
  @HiveField(2)
  DateTime? dataHoraFim;
  @HiveField(3)
  double valorTotalCalculado;
  @HiveField(4)
  String compraStatusId;
  @HiveField(5)
  bool isActive;
  @HiveField(6)
  bool isRemoved;
  @HiveField(7)
  DateTime createdAt;
  @HiveField(8)
  DateTime updatedAt;

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
}
