import 'package:hive/hive.dart';

part 'log_model.g.dart';

@HiveType(typeId: 31)
class LogModel {
  @HiveField(0)
  final String message;

  @HiveField(1)
  final String level; // 'debug' | 'info' | 'warn' | 'error'

  @HiveField(2)
  final DateTime timestamp;

  LogModel({
    required this.message,
    required this.level,
    required this.timestamp,
  });
}
