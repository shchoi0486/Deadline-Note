import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/ad_helper.dart';

class RewardedAdService {
  static RewardedAd? _rewardedAd;
  static bool _isAdLoading = false;

  /// 광고를 미리 로드해둡니다.
  static void loadAd() {
    if (_isAdLoading || _rewardedAd != null) return;

    _isAdLoading = true;
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
          debugPrint('Rewarded Ad loaded successfully');
        },
        onAdFailedToLoad: (error) {
          _isAdLoading = false;
          _rewardedAd = null;
          debugPrint('Rewarded Ad failed to load: $error');
        },
      ),
    );
  }

  /// 광고를 보여주고 보상 획득 여부를 반환합니다.
  static Future<bool> showAd({
    required VoidCallback onAdDismissed,
  }) async {
    if (_rewardedAd == null) {
      debugPrint('Rewarded Ad is not ready yet');
      loadAd(); // 다음을 위해 로드 시도
      return false;
    }

    final completer = Completer<bool>();
    bool rewarded = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadAd(); // 다음을 위해 미리 로드
        onAdDismissed();
        if (!completer.isCompleted) {
          completer.complete(rewarded);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadAd(); // 다음을 위해 미리 로드
        onAdDismissed();
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        rewarded = true;
      },
    );

    return completer.future;
  }

  /// 광고가 준비되었는지 확인합니다.
  static bool get isReady => _rewardedAd != null;
}
