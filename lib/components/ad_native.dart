import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:study_flutter_firebase/components/ad_helper.dart';

class AdNative {
  NativeAd? _nativeAd;
  bool _isLoaded = false; // 広告の読み込み状態

  bool get isLoaded => _isLoaded;

  VoidCallback? onAdLoaded; // 広告読み込み時のコールバック

  Future<void> load() async {
    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      factoryId: 'listTile',
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (Ad ad) {
          _nativeAd = ad as NativeAd;
          _isLoaded = true;
          onAdLoaded?.call(); // 広告読み込み完了時にコールバックを実行
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          debugPrint('Native Ad failed to load: $error');
          _isLoaded = false;
          ad.dispose();
        },
      ),
    );
    _nativeAd?.load();
  }

  /// ネイティブ広告のウィジェットを返す
  Widget getAdWidget() {
    if (_isLoaded && _nativeAd != null) {
      return Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: AdWidget(ad: _nativeAd!),
      );
    } else {
      return const SizedBox.shrink(); // 広告が読み込まれなかった場合は空のウィジェット
    }
  }

  /// リソースを破棄
  void dispose() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoaded = false;
  }
}

class AdNativeWidget extends StatefulWidget {
  const AdNativeWidget({Key? key}) : super(key: key);

  @override
  _AdNativeWidgetState createState() => _AdNativeWidgetState();
}

class _AdNativeWidgetState extends State<AdNativeWidget> {
  final AdNative _adNative = AdNative();

  @override
  void initState() {
    super.initState();
    _adNative.onAdLoaded = () {
      setState(() {}); // 広告が読み込まれたら再描画
    };
    _adNative.load();
  }

  @override
  void dispose() {
    _adNative.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _adNative.getAdWidget();
  }
}
