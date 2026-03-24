import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../services/job_link_parser.dart';
import '../state/app_state_scope.dart';

class JobBrowserScreen extends StatefulWidget {
  final String initialUrl;
  final String homeUrl;
  final String title;
  final Future<void> Function(String url)? onRegister;

  const JobBrowserScreen({
    required this.initialUrl,
    required this.homeUrl,
    required this.title,
    this.onRegister,
    super.key,
  });

  @override
  State<JobBrowserScreen> createState() => _JobBrowserScreenState();
}

class _JobBrowserScreenState extends State<JobBrowserScreen> {
  static const double _fabSize = 56;
  late final WebViewController _controller;
  bool _loading = true;
  double _progress = 0;
  String _currentUrl = '';
  double _fabRight = 16;
  double _fabBottom = 70;
  bool _isDraggingFab = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            // 특정 오류 코드(Terminal#998-1009 등)가 navigation_delegate 에러로 올 경우 처리
            debugPrint('Web resource error: ${error.errorCode} - ${error.description}');
            
            // 안드로이드에서 ERR_UNKNOWN_URL_SCHEME (-10) 등 커스텀 스킴 관련 에러가 발생할 경우
            // 에러 페이지가 뜨는 대신 뒤로가기나 홈으로 리다이렉트 시도
            if (error.errorCode == -10 || 
                error.description.contains('ERR_UNKNOWN_URL_SCHEME') ||
                error.description.contains('net::ERR_CONNECTION_REFUSED')) {
               _handleBack();
               return;
            }
            
            // 에러 발생 시에도 현재 URL을 업데이트하여 뒤로가기 로직이 작동하게 함
            _controller.currentUrl().then((url) {
              if (url != null && mounted) {
                setState(() => _currentUrl = url);
              }
            });
          },
          onPageStarted: (url) {
            setState(() {
              _loading = true;
              _currentUrl = url;
            });
          },
          onPageFinished: (url) {
            setState(() {
              _loading = false;
              _currentUrl = url;
            });
            // URL이 변경될 때마다 상태 업데이트 (초기 URL 제외)
            if (mounted) {
              AppStateScope.of(context).updateLastVisitedUrl(widget.title, url);
            }

            // 인크루트 등 일부 사이트의 레이아웃 리플로우 이슈 해결을 위한 스크립트 주입
            _controller.runJavaScript('''
              (function() {
                var fixLayout = function() {
                  var style = document.getElementById('deadline-note-fix');
                  var css = `
                    :root {
                      --safe-area-inset-bottom: 0px !important;
                    }
                    html, body, #__next, #app, #root {
                      padding-bottom: 0px !important;
                      margin-bottom: 0px !important;
                      height: 100% !important;
                      overflow-x: hidden;
                    }
                    /* 인크루트, 원티드 등 하단 바 강제 밀착 */
                    [class*="gnb"], [class*="foot"], [class*="bottom_menu"], #footer_spacer,
                    nav, [class*="BottomNav"], [class*="Navigation"], [class*="TabBar"],
                    [class*="NavigationBar"], [class*="MobileNav"] {
                      bottom: 0px !important;
                      padding-bottom: 0px !important;
                      margin-bottom: 0px !important;
                      transform: none !important; /* translateY 대신 none으로 완전히 초기화 */
                    }
                    /* 원티드 특정 하단 여백 요소 및 safe-area 대응 요소 강제 제거 */
                    div[style*="height: env(safe-area-inset-bottom)"],
                    div[style*="padding-bottom: env(safe-area-inset-bottom)"],
                    div[class*="SafeArea"], [class*="Spacing"], [class*="Gap"] {
                      display: none !important;
                      height: 0px !important;
                      padding-bottom: 0px !important;
                      margin-bottom: 0px !important;
                    }
                    /* 원티드 모바일 웹 특정 구조 대응 */
                    #__next > div > div:last-child {
                      padding-bottom: 0px !important;
                    }
                    /* 알바천국 팝업 등 레이어 팝업이 다른 요소에 가려지지 않도록 처리 */
                    .layer_popup, .popup_wrap, .layer_popup_type2 {
                      z-index: 999999 !important;
                    }
                    /* 클릭을 방해할 수 있는 투명 오버레이나 가상 요소 체크 */
                    .dimmed, .mask {
                      z-index: 999998 !important;
                    }
                  `;
                  
                  if (!style) {
                    style = document.createElement('style');
                    style.id = 'deadline-note-fix';
                    style.innerHTML = css;
                    document.head.appendChild(style);
                    window.dispatchEvent(new Event('resize'));
                  } else if (style.innerHTML !== css) {
                    style.innerHTML = css;
                  }

                  // JS로 하단 고정 요소 강제 조정 (CSS로 해결 안 되는 동적 스타일 대응)
                  // 주요 컨테이너 태그만 검사하여 성능 부하 최소화
                  var elements = document.querySelectorAll('div, nav, header, footer, section');
                  var windowHeight = window.innerHeight;
                  
                  for (var i = 0; i < elements.length; i++) {
                    var el = elements[i];
                    var style = window.getComputedStyle(el);
                    
                    // 원티드 특정 하단 바 클래스 감지 강화
                    var isWantedBar = el.className && typeof el.className === 'string' && 
                                     (el.className.includes('NavigationBar') || 
                                      el.className.includes('BottomNav') ||
                                      el.className.includes('TabBar') ||
                                      el.className.includes('Menu') ||
                                      el.className.includes('MobileNav'));

                    if (style.position === 'fixed' || style.position === 'sticky' || isWantedBar) {
                       var rect = el.getBoundingClientRect();
                       // 요소가 화면 하단 근처(70px 이내로 확대)에 있고, 높이가 적절한 경우
                       if ((rect.bottom >= windowHeight - 70 && rect.height < 200 && rect.height > 0) || isWantedBar) {
                         el.style.setProperty('bottom', '0px', 'important');
                         el.style.setProperty('margin-bottom', '0px', 'important');
                         el.style.setProperty('transform', 'none', 'important');
                         
                         // 내부의 safe-area 대응 패딩도 강제 제거
                         if (style.paddingBottom !== '0px') {
                           el.style.setProperty('padding-bottom', '0px', 'important');
                         }
                       }
                    }
                  }
                };
                
                // 실행 및 관찰
                fixLayout();
                var timeout;
                var observer = new MutationObserver(function(mutations) {
                  // 성능을 위해 디바운싱 처리 (0.2초)
                  clearTimeout(timeout);
                  timeout = setTimeout(fixLayout, 200);
                });
                if (document.body) {
                  observer.observe(document.body, { childList: true, subtree: true });
                }
              })();
            ''');
          },
          onProgress: (progress) {
            setState(() {
              _progress = progress / 100.0;
            });
          },
          onNavigationRequest: (request) async {
            final url = request.url;
            
            // 1. http, https 스킴 허용
            if (url.startsWith('http://') || url.startsWith('https://')) {
              // 앱 스토어 관련 링크는 navigate하지 않고 외부 앱으로 연결
              if (url.startsWith('market://') || 
                  url.startsWith('itms-apps://') ||
                  url.contains('play.google.com') ||
                  url.startsWith('intent://')) {
                final uri = Uri.parse(url);
                try {
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                } catch (_) {}
                return NavigationDecision.prevent;
              }
              return NavigationDecision.navigate;
            }
            
            // 2. 전화, 메일, SMS 등 외부 앱 연동 스킴 처리
            if (url.startsWith('tel:') || url.startsWith('mailto:') || url.startsWith('sms:')) {
              final uri = Uri.parse(url);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              } catch (_) {}
              return NavigationDecision.prevent;
            }

            // 3. intent 스킴 처리 (안드로이드 전용)
            if (url.startsWith('intent://')) {
              try {
                final uri = Uri.parse(url);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              } catch (_) {}
              return NavigationDecision.prevent;
            }
            
            // 4. javascript: 스킴은 허용 (팝업 닫기 등에 사용될 수 있음)
            if (url.startsWith('javascript:')) {
              return NavigationDecision.navigate;
            }
            
            // 5. 기타 커스텀 스킴 차단하되 외부 앱 실행 시도
            try {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                return NavigationDecision.prevent;
              }
            } catch (_) {}
            
            debugPrint('Blocking custom scheme navigation: $url');
            return NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _handleShare() async {
    final url = await _controller.currentUrl();
    if (url == null || !mounted) return;
    final onRegister = widget.onRegister;
    if (onRegister != null) {
      await onRegister(url);
      return;
    }
    Navigator.pop(context, url);
  }

  Future<void> _openExternal() async {
    final url = await _controller.currentUrl() ?? _currentUrl;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleBack() async {
    String currentUrl = await _controller.currentUrl() ?? _currentUrl;
    if (currentUrl.isEmpty) currentUrl = widget.homeUrl;

    final homeUri = Uri.parse(widget.homeUrl);
    final currentUri = Uri.parse(currentUrl);
    final currentHost = currentUri.host.replaceAll('m.', '').replaceAll('www.', '');
    final homeHost = homeUri.host.replaceAll('m.', '').replaceAll('www.', '');
    
    // 경로 비교 시 슬래시(/) 차이 무시
    final currentPath = currentUri.path.isEmpty || currentUri.path == '/' ? '/' : currentUri.path.replaceAll(RegExp(r'/$'), '');
    final homePath = homeUri.path.isEmpty || homeUri.path == '/' ? '/' : homeUri.path.replaceAll(RegExp(r'/$'), '');

    final isAtHome = currentHost == homeHost && 
                    currentPath == homePath &&
                    (currentUri.query == homeUri.query);

    // 1. 웹뷰 히스토리가 있으면 뒤로가기
    if (await _controller.canGoBack()) {
      debugPrint('JobBrowser: Going back in history');
      await _controller.goBack();
      return;
    }

    // 2. 히스토리는 없지만 현재 페이지가 메인(홈)이 아니면 메인으로 이동
    if (!isAtHome) {
      debugPrint('JobBrowser: Not at home. Loading homeUrl: ${widget.homeUrl}');
      await _controller.loadRequest(homeUri);
      return;
    }

    // 3. 메인 페이지이면서 히스토리가 없으면 브라우저 닫기
    debugPrint('JobBrowser: Already at home and no history. Popping...');
    if (mounted) {
      // 명시적으로 현재의 Navigator를 찾아서 팝
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        debugPrint('JobBrowser: onPopInvoked didPop=$didPop');
        if (didPop) return;
        await _handleBack();
      },
      child: Material(
        color: Colors.white,
        child: Stack(
          children: [
            Column(
              children: [
                // 커스텀 AppBar 영역
                SafeArea(
                  bottom: false,
                  child: Container(
                    height: 44,
                    color: Colors.white,
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            widget.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new_rounded, size: 20),
                          tooltip: '외부 브라우저에서 열기',
                          onPressed: _openExternal,
                          constraints: const BoxConstraints(),
                          padding: const EdgeInsets.all(8),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ),
                ),
                // 로딩바
                if (_loading)
                  LinearProgressIndicator(
                    value: _progress,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  )
                else
                  const SizedBox(height: 2),
                // WebView 영역 (Expanded로 남은 공간 꽉 채움)
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeBottom: true, // 하단 패딩(세이프 에어리어) 강제 제거
                    child: WebViewWidget(controller: _controller),
                  ),
                ),
              ],
            ),
            // FloatingActionButton (드래그 기능 개선)
            Positioned(
              right: _fabRight,
              bottom: _fabBottom,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (_) {
                  setState(() => _isDraggingFab = false); // 드래그 시작 시 초기화
                },
                onPanUpdate: (details) {
                  final size = MediaQuery.of(context).size;
                  setState(() {
                    _isDraggingFab = true; // 실제로 움직이면 드래그 중인 것으로 간주
                    _fabRight = (_fabRight - details.delta.dx).clamp(0, size.width - _fabSize);
                    _fabBottom = (_fabBottom - details.delta.dy).clamp(0, size.height - _fabSize - 80);
                  });
                },
                onPanEnd: (_) {
                  // 드래그 종료 시 약간의 지연 후 상태 해제하여 의도치 않은 클릭 방지
                  Future.delayed(const Duration(milliseconds: 100), () {
                    if (mounted) setState(() => _isDraggingFab = false);
                  });
                },
                child: SizedBox(
                  width: _fabSize,
                  height: _fabSize,
                  child: FloatingActionButton(
                    onPressed: () {
                      if (_isDraggingFab) return;
                      debugPrint('FAB Pressed');
                      _handleShare();
                    },
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.white, width: 2),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '일정',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                        Text(
                          '등록',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, height: 1.1),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
