import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'unidade_medida_model.g.dart';

@HiveType(typeId: 1)
class UnidadeMedidaModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  String descricao;
  @HiveField(2)
  String simbolo;
  @HiveField(3) // NOVO CAMPO
  bool isActive;
  @HiveField(4) // NOVO CAMPO
  bool isRemoved;

  UnidadeMedidaModel({
    String? id,
    required this.descricao,
    required this.simbolo,
    this.isActive = true, // NOVO PARÂMETRO
    this.isRemoved = false, // NOVO PARÂMETRO
  }) : id = id ?? const Uuid().v4();

  UnidadeMedidaModel copyWith({
    String? id,
    String? descricao,
    String? simbolo,
    bool? isActive, // NOVO PARÂMETRO
    bool? isRemoved, // NOVO PARÂMETRO
  }) {
    return UnidadeMedidaModel(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      simbolo: simbolo ?? this.simbolo,
      isActive: isActive ?? this.isActive, // NOVO NO COPYWITH
      isRemoved: isRemoved ?? this.isRemoved, // NOVO NO COPYWITH
    );
  }
}
