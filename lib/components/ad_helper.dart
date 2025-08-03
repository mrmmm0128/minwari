import 'dart:io';

class AdHelper {
  static String get bannerAdUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-8735314159015654/3727992057';
    } else {
      // ignore: unnecessary_new
      throw new UnsupportedError('Unsupported platform');
    }
  }

  static String get interstatialAdUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-8735314159015654/4522579846';
    } else {
      // ignore: unnecessary_new
      throw new UnsupportedError('Unsupported platform');
    }
  }

  static String get nativeAdUnitId {
    if (Platform.isIOS) {
      return 'ca-app-pub-3940256099942544/2247696110';
    } else {
      // ignore: unnecessary_new
      throw new UnsupportedError('Unsupported platform');
    }
  }
}
