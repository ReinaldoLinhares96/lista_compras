// ignore_for_file: use_build_context_synchronously

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
        } else if (purchaseDetails.status == PurchaseStatus.purchased) {
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
      appBar: AppBar(title: const Text('Seja Premium!')),
      body: _isAvailable
          ? _products.isEmpty
                ? Center(
                    child: Text(_queryProductError ?? 'Carregando produtos...'),
                  )
                : ListView.builder(
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return Card(
                        child: ListTile(
                          title: product.price.length == 6
                              ? Text('Teste Gratuito de 3 dias')
                              : product.price.length == 7
                              ? Text('Plano Premium Anual')
                              : product.price.length == 8
                              ? Text(' Plano Premium Mensal')
                              : Text(''),
                          subtitle: product.price.length == 6
                              ? Text(
                                  'Experimente todos os recursos Premium sem compromisso. Sem anúncios e com histórico disponível.',
                                )
                              : product.price.length == 7
                              ? Text(
                                  'Economize! Tenha acesso ilimitado aos recursos Premium o ano todo, com o melhor custo-benefício.',
                                )
                              : product.price.length == 8
                              ? Text(
                                  'Acesso total a todos os recursos Premium, com flexibilidade de renovação mensal.',
                                )
                              : Text(''),
                          trailing: ElevatedButton(
                            onPressed: _purchasePending
                                ? null
                                : () => _buyProduct(product),
                            child: _purchasePending
                                ? const CircularProgressIndicator()
                                : Text(product.price),
                          ),
                        ),
                      );
                    },
                  )
          : Center(
              child: Text(
                _queryProductError ??
                    'A loja de aplicativos não está disponível.',
              ),
            ),
    );
  }
}
