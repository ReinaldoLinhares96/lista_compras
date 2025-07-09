import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

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

  CategoriaModel({
    String? id,
    required this.descricao,
    this.isActive = true, // NOVO PARÂMETRO
    this.isRemoved = false, // NOVO PARÂMETRO
  }) : id = id ?? const Uuid().v4();

  CategoriaModel copyWith({
    String? id,
    String? descricao,
    bool? isActive, // NOVO PARÂMETRO
    bool? isRemoved, // NOVO PARÂMETRO
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      isActive: isActive ?? this.isActive, // NOVO NO COPYWITH
      isRemoved: isRemoved ?? this.isRemoved, // NOVO NO COPYWITH
    );
  }
}
