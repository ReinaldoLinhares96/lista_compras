// lib/data/repositories/premium_status_repository.dart

// ignore_for_file: depend_on_referenced_packages

import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

class PremiumStatusRepository {
  late Box<bool> _premiumStatusBox;
  static const _premiumStatusKey = 'isPremium';

  PremiumStatusRepository() {
    _premiumStatusBox = Hive.box<bool>('premiumStatusBox');
  }

  Future<void> initializeDefaultPremiumStatus() async {
    if (!_premiumStatusBox.containsKey(_premiumStatusKey)) {
      await _premiumStatusBox.put(_premiumStatusKey, false);
    }
  }

  Stream<bool> get isPremiumStream {
    return _premiumStatusBox
        .watch(key: _premiumStatusKey)
        .map((event) {
          return _premiumStatusBox.get(_premiumStatusKey, defaultValue: false)!;
        })
        .startWith(
          _premiumStatusBox.get(_premiumStatusKey, defaultValue: false)!,
        );
  }

  bool get isPremium =>
      _premiumStatusBox.get(_premiumStatusKey, defaultValue: false)!;

  Future<void> updatePremiumStatus(bool status) async {
    await _premiumStatusBox.put(_premiumStatusKey, status);
  }
}
