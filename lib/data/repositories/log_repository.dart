// ignore_for_file: no_leading_underscores_for_local_identifiers, depend_on_referenced_packages

import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';
import '../models/log_model.dart';

class LogRepository {
  static final LogRepository instance = LogRepository._internal();

  late final Box<LogModel> _logBox;

  LogRepository._internal();

  Future<void> init() async {
    _logBox = Hive.box<LogModel>('logBox');
    if (_logBox.isEmpty) {
      await addLog('Primeiro log', level: 'info');
    }
  }

  Future<void> addLog(String message, {String level = 'debug'}) async {
    await _logBox.add(
      LogModel(message: message, level: level, timestamp: DateTime.now()),
    );
  }

  Stream<List<LogModel>> watchAll() {
    List<LogModel> _sorted() {
      final list = _logBox.values.toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }

    return _logBox.watch().map((_) => _sorted()).startWith(_sorted());
  }

  Future<void> clearLogs() async => _logBox.clear();
}
