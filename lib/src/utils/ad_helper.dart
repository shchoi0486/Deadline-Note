class AdHelper {
  // 개발 중일 때 테스트 광고 적용 여부 (기기 등록이 되어있으므로 실제 ID를 사용해도 안전함)
  static const bool useTestAds = false;

  // 실제 광고 ID (사용자 제공 이미지 기반)
  static const String _realBannerId = 'ca-app-pub-7279511347629270/7666254793';
  static const String _realNativeId = 'ca-app-pub-7279511347629270/9262407492';
  static const String _realInterstitialId = 'ca-app-pub-7279511347629270/3108497453';
  static const String _realRewardedId = 'ca-app-pub-7279511347629270/6137985470';
  static const String _realRewardedInterstitialId = 'ca-app-pub-7279511347629270/7451067144';

  // 테스트 광고 ID (Google 공식 테스트 ID)
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testNativeId = 'ca-app-pub-3940256099942544/2247696110';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String _testRewardedId = 'ca-app-pub-3940256099942544/5224354917';

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
    return useTestAds ? _testRewardedId : _realRewardedInterstitialId;
  }
}
