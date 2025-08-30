// ignore_for_file: use_build_context_synchronously, unused_element, unnecessary_brace_in_string_interps

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:lista_compras/data/repositories/log_repository.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/premium_status_repository.dart';

// IDs dos seus produtos configurados nas lojas
const Set<String> _kProductIds = {'fortisacl.lista_compras.premium'};

class PremiumPurchasePage extends StatefulWidget {
  const PremiumPurchasePage({super.key});

  @override
  State<PremiumPurchasePage> createState() => _PremiumPurchasePageState();
}

class _PremiumPurchasePageState extends State<PremiumPurchasePage> {
  final LogRepository _logRepository = LogRepository.instance;
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;

  @override
  Future<void> initState() async {
    super.initState();
    _initStoreInfo();

    _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    });

    await _inAppPurchase.restorePurchases();
  }

  Future<void> _initStoreInfo() async {
    _isAvailable = await _inAppPurchase.isAvailable();

    _logRepository.addLog(
      '_isAvailable = ${_isAvailable}',
      level: '_initStoreInfo',
    );

    if (!_isAvailable) {
      setState(() {
        _queryProductError = 'A loja de aplicativos não está disponível.';
      });
      return;
    }

    final productDetailsResponse = await _inAppPurchase.queryProductDetails(
      _kProductIds,
    );

    _logRepository.addLog(
      '_kProductIds = ${_kProductIds.toList()}',
      level: '_initStoreInfo',
    );

    if (productDetailsResponse.error != null) {
      setState(() {
        _queryProductError = productDetailsResponse.error!.message;
      });
      return;
    }

    if (productDetailsResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError =
            'Nenhum produto encontrado. Verifique os IDs dos produtos.';
      });
      return;
    }

    setState(() {
      _products = productDetailsResponse.productDetails;
    });

    _logRepository.addLog(
      '_products (productDetailsResponse.productDetails) = ${_products.toList()}',
      level: '_initStoreInfo',
    );
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    final premiumStatusRepository = Provider.of<PremiumStatusRepository>(
      context,
      listen: false,
    );

    for (final purchaseDetails in purchaseDetailsList) {
      _logRepository.addLog(
        'Compra recebida: '
        'productID = ${purchaseDetails.productID}, '
        'purchaseID = ${purchaseDetails.purchaseID}, '
        'pendingCompletePurchase = ${purchaseDetails.pendingCompletePurchase}, '
        'status = ${purchaseDetails.status}'
        'error? = ${purchaseDetails.error}',
        level:
            '_listenToPurchaseUpdated - productDetailsResponse.productDetails',
      );

      if (purchaseDetails.status == PurchaseStatus.pending) {
        setState(() {
          _purchasePending = true;
        });
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erro na compra: ${purchaseDetails.error?.message}',
              ),
            ),
          );
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          await _deliverProduct(purchaseDetails, premiumStatusRepository);
          if (purchaseDetails.pendingCompletePurchase) {
            await _inAppPurchase.completePurchase(purchaseDetails);
          }
        }
      }
    }
    setState(() {
      _purchasePending = false;
    });
  }

  Future<void> _deliverProduct(
    PurchaseDetails purchaseDetails,
    PremiumStatusRepository premiumStatusRepository,
  ) async {
    _logRepository.addLog(
      'isPremium antes = ${premiumStatusRepository.isPremium}',
      level: '_deliverProduct',
    );

    await premiumStatusRepository.updatePremiumStatus(true);

    _logRepository.addLog(
      'isPremium depois = ${premiumStatusRepository.isPremium}',
      level: '_deliverProduct',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parabéns! Você agora é Premium!')),
    );
    Navigator.pop(context);
  }

  void _buyProduct(ProductDetails product) {
    _logRepository.addLog(
      'productID = ${product.id}, '
      'title = ${product.title}, '
      'currencyCode = ${product.currencyCode}, '
      'currencySymbol = ${product.currencySymbol}',
      level: '_buyProduct',
    );

    final purchaseParam = PurchaseParam(productDetails: product);

    _logRepository.addLog(
      'applicationUserName = ${purchaseParam.applicationUserName}, '
      'productID = ${purchaseParam.productDetails.id}.',
      level: '_buyProduct',
    );
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    setState(() {
      _purchasePending = true;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seja Premium!'),
        centerTitle: true,
        backgroundColor: Colors.blue.shade100,
      ),
      body: _isAvailable
          ? (_products.isEmpty && _queryProductError == null)
                ? const Center(child: CircularProgressIndicator())
                : _queryProductError != null
                ? Center(
                    child: Text(
                      'Erro ao carregar produtos: $_queryProductError',
                      textAlign: TextAlign.center,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _products.map((product) {
                      String title;
                      String description;
                      Color cardColor;

                      if (product.price.length <= 5) {
                        title = 'Plano Premium Mensal ${product.price.length}';
                        description =
                            'Acesso total a todos os recursos Premium, com flexibilidade de renovação mensal.';
                        cardColor = Colors.lightBlue.shade100;
                      }

                      if (product.price.length >= 6) {
                        title = 'Plano Premium Anual ${product.price.length}';
                        description =
                            'Economize! Tenha acesso ilimitado aos recursos Premium o ano todo, com o melhor custo-benefício.';
                        cardColor = Colors.lightGreen.shade100;
                      } else {
                        title = product.id.toString();
                        description = product.title.toString();
                        cardColor = Colors.red.shade100;
                      }

                      return Card(
                        elevation: 8,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 20),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: ElevatedButton(
                                  onPressed: _purchasePending
                                      ? null
                                      : () => _buyProduct(product),
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
                                          product.price,
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
                    }).toList(),
                  )
          : Center(
              child: Text(
                _queryProductError != null
                    ? 'A loja de aplicativos não está disponível.'
                    : ' ',
              ),
            ),
    );
  }
}
