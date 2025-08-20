import 'package:hive_flutter/hive_flutter.dart';
import '../models/log_model.dart';
import 'package:rxdart/rxdart.dart';

class LogRepository {
  late Box<LogModel> _logBox;

  LogRepository() {
    _logBox = Hive.box<LogModel>('logBox');
  }

  // Adiciona uma nova entrada de log
  Future<void> addLog({required String message, required String level}) async {
    final newLog = LogModel(message: message, level: level);
    await _logBox.put(newLog.id, newLog);
  }

  // Retorna um Stream com a lista de todos os logs, ordenados por timestamp
  Stream<List<LogModel>> getLogs() {
    return _logBox
        .watch()
        .map((event) {
          final allLogs = _logBox.values.toList();
          allLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          return allLogs;
        })
        .startWith(
          _logBox.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
        );
  }

  // Limpa todos os logs
  Future<void> clearLogs() async {
    await _logBox.clear();
  }
}
