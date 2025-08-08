import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'categoria_model.g.dart';

@HiveType(typeId: 2)
class CategoriaModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String descricao;
  @HiveField(2)
  bool isActive;
  @HiveField(3)
  bool isRemoved;

  CategoriaModel({
    String? id,
    required this.descricao,
    this.isActive = true,
    this.isRemoved = false,
  }) : id = id ?? const Uuid().v4();

  CategoriaModel copyWith({
    String? id,
    String? descricao,
    bool? isActive,
    bool? isRemoved,
  }) {
    return CategoriaModel(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      isActive: isActive ?? this.isActive,
      isRemoved: isRemoved ?? this.isRemoved,
    );
  }
}
