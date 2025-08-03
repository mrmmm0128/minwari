import 'package:study_flutter_firebase/components/ad_helper.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdInterstitial {
  InterstitialAd? _interstitialAd;

  /// インターステイシャル広告をロード
  void load() {
    InterstitialAd.load(
      adUnitId: AdHelper.interstatialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _interstitialAd?.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  /// インターステイシャル広告を表示
  void show() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null; // 使用後は破棄する
    } else {
      debugPrint('InterstitialAd is not ready to be shown.');
    }
  }

  /// リソースを破棄
  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }
}
