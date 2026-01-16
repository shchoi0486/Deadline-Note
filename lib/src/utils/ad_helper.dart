import 'package:flutter/foundation.dart';

class AdHelper {
  // 개발 중일 때 테스트 광고 적용 여부 (사용자 요청에 따라 True/False로 조절 가능하도록 함)
  static const bool useTestAds = kDebugMode;

  // 실제 광고 ID (사용자 제공 이미지 기반)
  static const String _realBannerId = 'ca-app-pub-4511718702168477/9106610425';
  static const String _realNativeId = 'ca-app-pub-4511718702168477/1036548710';
  static const String _realInterstitialId = 'ca-app-pub-4511718702168477/7804889628';
  static const String _realRewardedId = 'ca-app-pub-4511718702168477/9956835275';
  static const String _realRewardedInterstitialId = 'ca-app-pub-4511718702168477/8593257490';
  static const String _realAppOpenId = 'ca-app-pub-4511718702168477/4090905707';

  // 테스트 광고 ID (Google 공식 테스트 ID)
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testNativeId = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';
  static const String _testAppOpenId = 'ca-app-pub-3940256099942544/3419835294';

  static String get bannerAdUnitId {
    return useTestAds ? _testBannerId : _realBannerId;
  }

  static String get nativeAdUnitId {
    return useTestAds ? _testNativeId : _realNativeId;
  }

  static String get interstitialAdUnitId {
    return useTestAds ? _testInterstitialId : _realInterstitialId;
  }

  static String get rewardedAdUnitId {
    return useTestAds ? _testRewardedId : _realRewardedId;
  }

  static String get rewardedInterstitialAdUnitId {
    // Rewarded Interstitial은 테스트 ID가 별도로 명시되지 않은 경우 Rewarded 테스트 ID를 대용하거나 실제 ID를 사용
    return useTestAds ? _testRewardedId : _realRewardedInterstitialId;
  }

  static String get appOpenAdUnitId {
    return useTestAds ? _testAppOpenId : _realAppOpenId;
  }
}
