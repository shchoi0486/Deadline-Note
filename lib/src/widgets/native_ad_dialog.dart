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
          size: 16.0, // 다시 16으로 복구하여 가시성 확보
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF111111),
          style: NativeTemplateFontStyle.bold,
          size: 16.0, // 제목 크기 복구
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF666666),
          style: NativeTemplateFontStyle.normal,
          size: 14.0, // 설명 크기 복구
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: const Color(0xFF999999),
          style: NativeTemplateFontStyle.normal,
          size: 12.0, // 기타 텍스트 크기 복구
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
          padding: const EdgeInsets.symmetric(horizontal: 40), // 다시 40으로 복구하여 넓이 확보
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // White Card containing the Native Ad and "Remove Ads" button
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Native Ad View
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: SizedBox(
                        height: 340, // 높이를 340으로 다시 늘려 버튼 영역 확보
                        width: double.infinity,
                        child: AdWidget(ad: _nativeAd!),
                      ),
                    ),
                    
                    // Divider with subtle color
                    Divider(height: 1, thickness: 1, color: Colors.grey[100]),

                    // Remove Ads Button
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
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16), // 패딩 조정
                          alignment: Alignment.center,
                          child: Text(
                            l10n.adRemove,
                            style: TextStyle(
                              color: Colors.grey[600], // 더 진한 색으로 시인성 개선
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              letterSpacing: -0.5,
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
