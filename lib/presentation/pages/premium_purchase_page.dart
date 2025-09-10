// ignore_for_file: use_build_context_synchronously, unused_element, unnecessary_brace_in_string_interps, unnecessary_string_interpolations, unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lista_compras/services/billing_service.dart';
import 'package:lista_compras/data/repositories/log_repository.dart';
import '../../data/repositories/premium_status_repository.dart';
import 'package:lista_compras/main.dart';

class PremiumPurchasePage extends StatefulWidget {
  const PremiumPurchasePage({super.key});

  @override
  State<PremiumPurchasePage> createState() => _PremiumPurchasePageState();
}

class _PremiumPurchasePageState extends State<PremiumPurchasePage> {
  final PremiumStatusRepository _premiumStatusRepository =
      premiumStatusRepository;
  final LogRepository _logRepository = LogRepository();

  // Variável para ouvir as mudanças no stream de status premium
  late StreamSubscription<bool> _premiumStatusSubscription;

  List<dynamic> _products = [];
  bool _loading = true;
  bool _purchasePending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _restorePurchases();

    // 2. INICIE O "OUVINTE" DO STATUS PREMIUM
    // Este código ficará esperando uma mudança no status.
    _premiumStatusSubscription = _premiumStatusRepository.isPremiumStream
        .listen((isPremium) {
          // Se o status mudar para TRUE e a tela ainda estiver visível...
          if (isPremium && mounted) {
            // ...significa que a compra foi concluída com sucesso!
            // _logRepository.addLog(
            //   "Premium status mudou para true, mostrando sucesso.",
            // );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Parabéns! Você agora é Premium!")),
            );
            // Fecha a tela de compras, pois o objetivo foi alcançado.
            Navigator.of(context).pop();
          }
        });
  }

  Future<void> _loadProducts() async {
    try {
      final products = await BillingService.getProducts([
        'fortisacl.lista_compras.premium',
        'fortisacl.lista_compras.anual',
      ]);
      setState(() {
        _products = products;
        _loading = false;
      });

      // _logRepository.addLog("_loadProducts: $products");
    } catch (e) {
      setState(() {
        _error = "Erro ao carregar produtos: $e";
        _loading = false;
      });
      // _logRepository.addLog("_loadProducts ERRO: $e");
    }
  }

  Future<void> _restorePurchases() async {
    try {
      final restored = await BillingService.restorePurchases();
      // _logRepository.addLog("_restorePurchases: $restored");

      if (restored.isNotEmpty) {
        await _premiumStatusRepository.updatePremiumStatus(true);
      }
    } catch (e) {
      //_logRepository.addLog("_restorePurchases ERRO: $e");
    }
  }

  Future<void> _buy(String productId) async {
    setState(() => _purchasePending = true);
    try {
      await BillingService.buyProduct(productId);
      //_logRepository.addLog("_buy($productId) foi iniciado.");
    } catch (e) {
      // _logRepository.addLog("_buy ERRO: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Erro ao iniciar compra: $e")));
    } finally {
      if (mounted) {
        setState(() => _purchasePending = false);
      }
    }
  }

  @override
  void dispose() {
    _premiumStatusSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Seja Premium!"),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final mensalId = "fortisacl.lista_compras.premium";
                final anualId = "fortisacl.lista_compras.anual";
                final price = product["price"] ?? "R\$ -";

                return Card(
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          price.toString().length == 7
                              ? "Plano Anual"
                              : "Plano Mensal",
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                        const SizedBox(height: 8),
                        price.toString().length == 7
                            ? Text(
                                "Economize! Tenha acesso ilimitado aos recursos Premium o ano todo, com o melhor custo-benefício.",
                              )
                            : Text(
                                "Acesso total a todos os recursos Premium, com flexibilidade de renovação mensal.",
                              ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed: _purchasePending
                                ? null
                                : () => _buy(
                                    price.toString().length == 7
                                        ? anualId
                                        : mensalId,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            child: _purchasePending
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    price,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
