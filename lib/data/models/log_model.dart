import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'log_model.g.dart';

@HiveType(typeId: 8) // Use um typeId único e não utilizado
class LogModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String message;
  @HiveField(2)
  final String level; // Ex: 'DEBUG', 'ERROR', 'INFO'
  @HiveField(3)
  final DateTime timestamp;

  LogModel({
    String? id,
    required this.message,
    required this.level,
    DateTime? timestamp,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();
}
