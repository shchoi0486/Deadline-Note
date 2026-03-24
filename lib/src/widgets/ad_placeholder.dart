import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/ad_helper.dart';
import '../state/app_state_scope.dart';

class AdPlaceholder extends StatefulWidget {
  const AdPlaceholder({super.key});

  @override
  State<AdPlaceholder> createState() => _AdPlaceholderState();
}

class _AdPlaceholderState extends State<AdPlaceholder> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isAdLoading = false;
  bool _isDisposed = false;
  Timer? _loadingTimer; // 로딩 타임아웃 타이머 추가

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isLoaded && !_isAdLoading && !_isDisposed) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    if (_isDisposed) return;
    setState(() {
      _isAdLoading = true;
    });

    // 3초 타임아웃 타이머 시작
    _loadingTimer?.cancel();
    _loadingTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_isLoaded && _isAdLoading) {
        debugPrint('BannerAd load timed out (3s)');
        setState(() {
          _isAdLoading = false;
        });
        _bannerAd?.dispose();
        _bannerAd = null;
      }
    });

    try {
      // 화면 너비에서 여백(좌우 16 * 2 = 32)을 뺀 실제 광고 너비 계산
      final screenWidth = MediaQuery.of(context).size.width;
      final adWidth = (screenWidth - 32).truncate();

      final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
        adWidth,
      );

      if (!mounted || _isDisposed) {
        _loadingTimer?.cancel();
        return;
      }

      _bannerAd = BannerAd(
        adUnitId: AdHelper.bannerAdUnitId,
        request: const AdRequest(),
        size: size ?? AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _loadingTimer?.cancel(); // 로드 성공 시 타이머 취소
            if (mounted && ad == _bannerAd && !_isDisposed) {
              setState(() {
                _isLoaded = true;
                _isAdLoading = false;
              });
            }
          },
          onAdFailedToLoad: (ad, err) {
            _loadingTimer?.cancel(); // 로드 실패 시 타이머 취소
            debugPrint('BannerAd failed to load: $err');
            ad.dispose();
            if (mounted && ad == _bannerAd && !_isDisposed) {
              setState(() {
                _isLoaded = false;
                _isAdLoading = false;
              });
            }
          },
        ),
      )..load();
    } catch (e) {
      _loadingTimer?.cancel(); // 에러 시 타이머 취소
      debugPrint('Error getting ad size: $e');
      if (mounted && !_isDisposed) {
        setState(() {
          _isAdLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _loadingTimer?.cancel(); // 종료 시 타이머 취소
    _isDisposed = true;
    _bannerAd?.dispose();
    _bannerAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    if (appState.settings.adsRemoved) return const SizedBox.shrink();

    // 광고가 로드된 경우
    if (_isLoaded && _bannerAd != null && !_isDisposed) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 2, 16, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                alignment: Alignment.center,
                width: double.infinity,
                // 내부 패딩 최소화
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: SizedBox(
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(
                    ad: _bannerAd!,
                    key: ValueKey('banner_ad_${_bannerAd.hashCode}'),
                  ),
                ),
              ),
            ),
          ),
          // const SizedBox(height: 2), // 하단 간격 추가 제거
        ],
      );
    }

    // 광고 로딩 중이거나 로드 실패 시에는 공간을 차지하지 않도록 함
    return const SizedBox.shrink();
  }
}

