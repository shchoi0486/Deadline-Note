import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:deadline_note/l10n/app_localizations.dart';
import '../utils/ad_helper.dart';
import '../state/app_state_scope.dart';

class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({super.key});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isDisposed = false;
  bool _hasError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_nativeAd == null && !_hasError) {
      _loadAd();
    }
  }

  void _loadAd() {
    if (_nativeAd != null || _isDisposed) return;

    setState(() {
      _hasError = false;
    });

    final colorScheme = Theme.of(context).colorScheme;
    _nativeAd = NativeAd(
      adUnitId: AdHelper.nativeAdUnitId,
      request: const AdRequest(),
      nativeAdOptions: NativeAdOptions(
        videoOptions: VideoOptions(
          startMuted: true,
          clickToExpandRequested: true,
          customControlsRequested: false,
        ),
        adChoicesPlacement: AdChoicesPlacement.topRightCorner,
        mediaAspectRatio: MediaAspectRatio.any,
      ),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted && ad == _nativeAd && !_isDisposed) {
            setState(() {
              _isLoaded = true;
              _hasError = false;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('NativeAd failed to load: $error');
          ad.dispose();
          if (mounted && ad == _nativeAd && !_isDisposed) {
            setState(() {
              _nativeAd = null;
              _isLoaded = false;
              _hasError = true;
            });
          }
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: colorScheme.surface,
        cornerRadius: 16.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onSurface,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onSurfaceVariant,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: colorScheme.onSurfaceVariant,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _nativeAd?.dispose();
    _nativeAd = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = AppStateScope.of(context);
    if (appState.settings.adsRemoved) return const SizedBox.shrink();

    if (_isLoaded && _nativeAd != null && !_isDisposed) {
      return Container(
        height: 220,
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        child: AdWidget(ad: _nativeAd!),
      );
    }
    
    return SizedBox(
      height: 220,
      child: Center(
        child: _hasError
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ad_units_outlined, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 8),
                Text(l10n.adLoadError, style: const TextStyle(fontSize: 12)),
              ],
            )
          : const CircularProgressIndicator(),
      ),
    );
  }
}
