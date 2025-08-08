import 'package:hive/hive.dart';

part 'compra_status_model.g.dart';

@HiveType(typeId: 5)
class CompraStatusModel extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String descricao;
  @HiveField(2)
  bool isActive;
  @HiveField(3)
  bool isRemoved;

  CompraStatusModel({
    required this.id,
    required this.descricao,
    this.isActive = true,
    this.isRemoved = false,
  });

  CompraStatusModel copyWith({
    String? id,
    String? descricao,
    bool? isActive,
    bool? isRemoved,
  }) {
    return CompraStatusModel(
      id: id ?? this.id,
      descricao: descricao ?? this.descricao,
      isActive: isActive ?? this.isActive,
      isRemoved: isRemoved ?? this.isRemoved,
    );
  }
}
