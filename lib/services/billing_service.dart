import 'package:flutter/services.dart';

class BillingService {
  static const MethodChannel _channel = MethodChannel(
    "com.fortisacl.lista_compras_inteligente/billing",
  );

  /// Lista produtos disponíveis
  static Future<List<dynamic>> getProducts(List<String> productIds) async {
    final result = await _channel.invokeMethod("getProducts", {
      "productIds": productIds,
    });
    return List<dynamic>.from(result);
  }

  /// Inicia uma compra
  static Future<String> buyProduct(String productId) async {
    final result = await _channel.invokeMethod("buyProduct", {
      "productId": productId,
    });
    return result.toString();
  }

  /// Restaura compras (assinaturas ativas ou não consumíveis)
  static Future<List<dynamic>> restorePurchases() async {
    final result = await _channel.invokeMethod("restorePurchases");
    return List<dynamic>.from(result);
  }
}
