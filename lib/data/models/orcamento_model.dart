import 'package:hive/hive.dart';

part 'orcamento_model.g.dart';

@HiveType(typeId: 6)
class OrcamentoModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double valorMaximo;
  @HiveField(2)
  DateTime updatedAt;
  @HiveField(3) // NOVO CAMPO
  bool isActive;
  @HiveField(4) // NOVO CAMPO
  bool isRemoved;

  OrcamentoModel({
    required this.id,
    required this.valorMaximo,
    DateTime? updatedAt,
    this.isActive = true, // NOVO PARÂMETRO
    this.isRemoved = false, // NOVO PARÂMETRO
  }) : updatedAt = updatedAt ?? DateTime.now();

  OrcamentoModel copyWith({
    String? id,
    double? valorMaximo,
    DateTime? updatedAt,
    bool? isActive, // NOVO PARÂMETRO
    bool? isRemoved, // NOVO PARÂMETRO
  }) {
    return OrcamentoModel(
      id: id ?? this.id,
      valorMaximo: valorMaximo ?? this.valorMaximo,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive, // NOVO NO COPYWITH
      isRemoved: isRemoved ?? this.isRemoved, // NOVO NO COPYWITH
    );
  }
}
