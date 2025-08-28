// ignore_for_file: no_leading_underscores_for_local_identifiers, depend_on_referenced_packages

import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../models/log_model.dart';

class LogRepository {
  late final Box<LogModel> _logBox;

  LogRepository() {
    _logBox = Hive.box<LogModel>('logBox');
  }

  Future<void> initializeDefaultLog() async {
    if (_logBox.isEmpty) {
      await addLog('Primeiro log', level: 'info');
    }
  }

  Future<void> addLog(String message, {String level = 'debug'}) async {
    await _logBox.add(
      LogModel(message: message, level: level, timestamp: DateTime.now()),
    );
  }

  /// Stream que:
  /// 1) começa com o estado atual (startWith)
  /// 2) emite uma nova lista ordenada sempre que o box muda
  Stream<List<LogModel>> watchAll() {
    List<LogModel> _sorted() {
      final list = _logBox.values.toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }

    return _logBox
        .watch() // eventos de add/put/delete
        .map((_) => _sorted())
        .startWith(_sorted());
  }

  Future<void> clearLogs() async => _logBox.clear();
}
