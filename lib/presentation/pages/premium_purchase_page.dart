// ignore_for_file: use_build_context_synchronously, unused_element

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/premium_status_repository.dart';

// IDs dos seus produtos configurados nas lojas
const String _kPremiumProduct = 'fortisacl.lista_compras.anual';
const Set<String> _kProductIds = {_kPremiumProduct};

class PremiumPurchasePage extends StatefulWidget {
  const PremiumPurchasePage({super.key});

  @override
  State<PremiumPurchasePage> createState() => _PremiumPurchasePageState();
}

class _PremiumPurchasePageState extends State<PremiumPurchasePage> {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  List<ProductDetails> _products = [];
  bool _isAvailable = false;
  bool _purchasePending = false;
  String? _queryProductError;

  @override
  void initState() {
    super.initState();
    _initStoreInfo();
    _subscription = _inAppPurchase.purchaseStream.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription.cancel();
      },
      onError: (Object error) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro na compra: $error')));
        setState(() {
          _purchasePending = false;
        });
      },
    );
  }

  Future<void> _initStoreInfo() async {
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      setState(() {
        _queryProductError = 'A loja de aplicativos não está disponível.';
      });
      return;
    }

    final productDetailsResponse = await _inAppPurchase.queryProductDetails(
      _kProductIds,
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
  }

  bool _isFreeTrial(PurchaseDetails purchase) {
    return purchase.productID.contains('premium') &&
        purchase.status == PurchaseStatus.purchased &&
        purchase.pendingCompletePurchase;
  }

  Future<void> _listenToPurchaseUpdated(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    final premiumStatusRepository = Provider.of<PremiumStatusRepository>(
      context,
      listen: false,
    );

    for (final purchaseDetails in purchaseDetailsList) {
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
            purchaseDetails.status == PurchaseStatus.restored ||
            (purchaseDetails.status == PurchaseStatus.pending &&
                _isFreeTrial(purchaseDetails))) {
          await _deliverProduct(purchaseDetails, premiumStatusRepository);
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
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
    await premiumStatusRepository.updatePremiumStatus(true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Parabéns! Você agora é Premium!')),
    );
    Navigator.pop(context);
  }

  void _buyProduct(ProductDetails product) {
    final purchaseParam = PurchaseParam(productDetails: product);
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    setState(() {
      _purchasePending = true;
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
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

                      if (product.price.length == 6) {
                        title = 'Teste Gratuito de 3 dias';
                        description =
                            'Experimente todos os recursos Premium sem compromisso. Sem anúncios e com histórico disponível.';
                        cardColor = Colors.lightBlue.shade100;
                      } else if (product.price.length == 7) {
                        title = 'Plano Premium Anual';
                        description =
                            'Economize! Tenha acesso ilimitado aos recursos Premium o ano todo, com o melhor custo-benefício.';
                        cardColor = Colors.green.shade100;
                      } else {
                        title = 'Plano Premium Mensal';
                        description =
                            'Acesso total a todos os recursos Premium, com flexibilidade de renovação mensal.';
                        cardColor = Colors.deepPurple.shade100;
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
