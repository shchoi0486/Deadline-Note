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
  late final String _randomMessage;

  final List<String> _encouragementMessages = [
    '오늘도 정말 수고 많으셨어요!\n내일은 더 좋은 기회가 올 거예요.',
    '당신의 열정을 응원합니다.\n포기하지 마세요!',
    '조금 늦더라도 괜찮아요.\n당신만의 속도로 가고 있는 거니까요.',
    '오늘의 노력이\n내일의 합격으로 이어질 거예요.',
    '당신은 충분히 잘하고 있습니다.\n스스로를 믿으세요.',
    '실패는 성공으로 가는 과정일 뿐이에요.\n다시 일어날 수 있어요!',
    '지치고 힘들 땐 잠시 쉬어가도 좋아요.\n당신은 소중하니까요.',
    '꿈을 향한 당신의 걸음을\nDeadline Note가 함께 응원합니다.',
    '당신이라는 원석이 곧\n보석처럼 빛날 날이 올 거예요.',
    '힘들었던 시간만큼\n더 큰 기쁨이 기다리고 있을 거예요.',
    '당신의 가능성은 무한합니다.\n자신감을 가지세요!',
    '한 걸음 한 걸음이 모여\n큰 성취를 이룰 거예요.',
    '당신의 가치를 알아주는 곳이\n반드시 나타날 거예요.',
    '오늘도 한 뼘 더 성장한\n당신을 칭찬해주세요.',
    '어두운 밤이 지나면\n반드시 밝은 아침이 찾아옵니다.',
    '당신은 결코 혼자가 아니에요.\n우리가 응원하고 있어요!',
    '지금의 인내가 훗날\n멋진 열매를 맺을 거예요.',
    '당신의 성실함은 배신하지 않을 거예요.\n힘내세요!',
    '세상에 단 하나뿐인\n당신의 꿈을 응원합니다.',
    '할 수 있다는 믿음이\n기적을 만듭니다.',
    '오늘도 최선을 다한\n당신에게 박수를 보냅니다.',
    '당신의 내일이 오늘보다\n더 반짝이기를 바랍니다.',
    '두려워하지 말고 나아가세요.\n당신은 할 수 있습니다!',
    '매일 조금씩 나아가는\n당신의 모습이 아름다워요.',
    '합격이라는 마침표가 머지않았습니다.\n조금만 더 힘내세요!',
    '당신의 열정적인 삶이\n멋진 결실을 맺을 거예요.',
    '스스로를 사랑하는 마음이\n가장 큰 힘이 됩니다.',
    '당신의 노력이 헛되지 않음을\n결과로 증명될 거예요.',
    '오늘도 꿈에 한 발짝 더\n가까워지셨네요!',
    '당신의 앞날에 꽃길만 가득하기를\n진심으로 기원합니다.',
  ];

  @override
  void initState() {
    super.initState();
    _randomMessage = _encouragementMessages[DateTime.now().millisecond % _encouragementMessages.length];
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
              // White Card containing the Native Ad
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
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
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 240,
                          maxHeight: 280,
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: AdWidget(ad: _nativeAd!),
                        ),
                      ),
                    ),
                    
                    // Footer with Message and Close Button
                    Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                      ),
                      child: Row(
                        children: [
                          // 응원 메시지 박스 (가로로 확장)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F4FF),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFD0E0FF), width: 1),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome, color: Color(0xFF4A80FF), size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _randomMessage,
                                      style: const TextStyle(
                                        color: Color(0xFF204080),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        height: 1.3,
                                        letterSpacing: -0.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 닫기 버튼 (오른쪽 배치)
                          SizedBox(
                            height: 44,
                            child: FilledButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: Text(
                                l10n.close,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
