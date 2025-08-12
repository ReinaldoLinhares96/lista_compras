import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'premium_status_model.g.dart';

@HiveType(typeId: 7) // Certifique-se de que este ID seja único
class PremiumStatusModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late bool isPremium;

  @HiveField(2)
  late DateTime createdAt;

  @HiveField(3)
  late DateTime updatedAt;

  @HiveField(4)
  late bool isActive;

  @HiveField(5)
  late bool isRemoved;

  PremiumStatusModel({
    required this.id,
    required this.isPremium,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isRemoved,
  });

  // Construtor de fábrica para criar um status padrão
  factory PremiumStatusModel.create() {
    final now = DateTime.now();
    return PremiumStatusModel(
      id: const Uuid().v4(),
      isPremium: false,
      createdAt: now,
      updatedAt: now,
      isActive: true,
      isRemoved: false,
    );
  }

  // Método para copiar o modelo com novos valores
  PremiumStatusModel copyWith({
    String? id,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isRemoved,
  }) {
    return PremiumStatusModel(
      id: id ?? this.id,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isRemoved: isRemoved ?? this.isRemoved,
    );
  }
}
