import 'package:deadline_note/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/ad_helper.dart';
import '../state/app_state_scope.dart';

class NativeAdDialog extends StatefulWidget {
  const NativeAdDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final appState = AppStateScope.of(context);
    if (appState.settings.adsRemoved) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const NativeAdDialog(),
    );
  }

  @override
  State<NativeAdDialog> createState() => _NativeAdDialogState();
}

class _NativeAdDialogState extends State<NativeAdDialog> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      factoryId: 'adFactoryExample', // This is ignored if using nativeTemplateStyle
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        videoOptions: VideoOptions(
          startMuted: true,
          clickToExpandRequested: true,
          customControlsRequested: false,
        ),
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd failed to load: $error');
          ad.dispose();
          // If ad fails to load, just close the dialog or show nothing?
          // For now, let's just close the dialog automatically if it fails
          if (mounted) {
             Navigator.of(context).pop();
          }
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF2E5BFF),
          style: NativeTemplateFontStyle.bold,
          size: 14.0, // 버튼 텍스트 크기 약간 축소
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF111111),
          style: NativeTemplateFontStyle.bold,
          size: 15.0, // 제목 크기 약간 축소
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF666666),
          style: NativeTemplateFontStyle.normal,
          size: 13.0, // 설명 크기 약간 축소
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF999999),
          style: NativeTemplateFontStyle.normal,
          size: 11.0, // 기타 텍스트 크기 축소
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isAdLoaded) {
      return const SizedBox.shrink(); // Show nothing while loading
    }

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // White Card containing the Native Ad and "Remove Ads" button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Native Ad View
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 280,
                          maxHeight: 340,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: AdWidget(ad: _nativeAd!),
                        ),
                      ),
                    ),
                    
                    // Remove Ads Button (Visible enough, but not distracting)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.adRemovePending),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14), // 클릭 영역 및 가독성 확보
                          alignment: Alignment.center,
                          child: Text(
                            l10n.adRemove,
                            style: TextStyle(
                              color: Colors.grey[600], // 색상을 더 진하게 변경
                              fontWeight: FontWeight.w600, // 더 굵게
                              fontSize: 13, // 크기 키움
                              letterSpacing: -0.4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),

              // Close Button (Improved Visibility)
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5), // 더 어두운 배경으로 대비 강화
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.close,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        shadows: [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
