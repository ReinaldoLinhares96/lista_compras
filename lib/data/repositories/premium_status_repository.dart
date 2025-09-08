// lib/data/repositories/premium_status_repository.dart

// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/services.dart'; // NOVO: Import necessário para o MethodChannel
import 'package:hive_flutter/hive_flutter.dart';
import 'package:rxdart/rxdart.dart';

class PremiumStatusRepository {
  late Box<bool> _premiumStatusBox;
  static const _premiumStatusKey = 'isPremium';

  // NOVO: Definição do MethodChannel, o mesmo usado no BillingService
  static const MethodChannel _channel = MethodChannel(
    "com.fortisacl.lista_compras_inteligente/billing",
  );

  PremiumStatusRepository() {
    _premiumStatusBox = Hive.box<bool>('premiumStatusBox');

    // NOVO: Inicia o "ouvinte" assim que o repositório é criado.
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  // NOVO: Função que trata as chamadas vindas do lado nativo (Kotlin)
  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case "purchaseSuccess":
        await updatePremiumStatus(true);
        break;
      case "purchaseCanceled":
        break;
      case "purchaseError":
        break;
    }
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
