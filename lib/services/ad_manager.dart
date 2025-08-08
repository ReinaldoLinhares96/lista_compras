// lib/services/ad_manager.dart

// ignore_for_file: constant_identifier_names, unused_import

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AdManager {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoaded = false;
  static const String _adUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712' // ID de teste do Google
      : 'SEU_ID_DE_BLOCO_INTERSTICIAL_REAL'; // SUBSTITUA EM PRODUÇÃO

  // Contador de interações para controlar a frequência
  static int _interactionCount = 0;
  static const int INTERACTION_THRESHOLD =
      5; // Mostrar anúncio a cada 5 interações

  // Carregar o anúncio intersticial
  static void loadInterstitialAd() {
    if (_isInterstitialAdLoaded) return;

    InterstitialAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          debugPrint('Interstitial Ad loaded.');
          _interstitialAd?.fullScreenContentCallback =
              FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  ad.dispose();
                  _isInterstitialAdLoaded = false;
                  loadInterstitialAd(); // Carregar o próximo anúncio
                },
                onAdFailedToShowFullScreenContent: (ad, err) {
                  debugPrint('Interstitial Ad failed to show: $err');
                  ad.dispose();
                  _isInterstitialAdLoaded = false;
                  loadInterstitialAd(); // Tentar recarregar
                },
              );
        },
        onAdFailedToLoad: (LoadAdError err) {
          debugPrint('Interstitial Ad failed to load: $err');
          _interstitialAd?.dispose();
          _isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  // Exibir o anúncio intersticial se estiver carregado e o limite for atingido
  static void maybeShowInterstitialAd() async {
    _interactionCount++;
    if (_interactionCount >= INTERACTION_THRESHOLD) {
      if (_isInterstitialAdLoaded && _interstitialAd != null) {
        _interstitialAd?.show();
        _isInterstitialAdLoaded = false; // Resetar o estado
        _interactionCount = 0; // Resetar o contador
      } else {
        debugPrint('Interstitial Ad not ready to show. Loading a new one.');
        loadInterstitialAd(); // Tentar carregar se não estiver pronto
      }
    }
  }

  // Método para descartar o anúncio
  static void disposeAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
  }
}
