import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/ad_helper.dart';
import '../widgets/native_ad_dialog.dart';

import '../state/app_state_scope.dart';

class AdManager {
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialAdLoading = false;

  static void loadInterstitialAd() {
    if (_isInterstitialAdLoading || _interstitialAd != null) return;
    _isInterstitialAdLoading = true;

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdLoading = false;
          debugPrint('InterstitialAd loaded');
          
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd(); // Load next one
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdLoading = false;
          _interstitialAd = null;
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  static void showInterstitialAd({VoidCallback? onAdDismissed}) {
    // 홍보용 이미지 촬영을 위해 일시적으로 전면 광고 숨김
    onAdDismissed?.call();
    return;
    
    if (_interstitialAd == null) {
      onAdDismissed?.call();
      loadInterstitialAd();
      return;
    }

    if (onAdDismissed != null) {
      final prevCallback = _interstitialAd!.fullScreenContentCallback;
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          prevCallback?.onAdDismissedFullScreenContent?.call(ad);
          onAdDismissed();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          prevCallback?.onAdFailedToShowFullScreenContent?.call(ad, error);
          onAdDismissed();
        },
      );
    }

    _interstitialAd!.show();
  }

  static Future<void> showNativeAdDialog(BuildContext context) async {
    final appState = AppStateScope.of(context);
    if (appState.settings.adsRemoved) return;
    
    return NativeAdDialog.show(context);
  }
}
