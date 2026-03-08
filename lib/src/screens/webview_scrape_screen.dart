import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebviewScrapeScreen extends StatefulWidget {
  const WebviewScrapeScreen({required this.targetUrl, super.key});
  final String targetUrl;
  @override
  State<WebviewScrapeScreen> createState() => _WebviewScrapeScreenState();
}

class _WebviewScrapeScreenState extends State<WebviewScrapeScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (NavigationRequest request) {
          // market:// 또는 intent:// 스킴이 포함된 URL은 외부 앱 실행 시도이므로 차단
          if (request.url.startsWith('market://') || 
              request.url.startsWith('itms-apps://') ||
              request.url.contains('play.google.com') ||
              request.url.startsWith('intent://')) {
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageFinished: (_) async {
          // 페이지 로드 완료 시 차단 여부 및 데이터 추출 시도 (자동화 보조)
        },
      ));
    _start();
  }

  Future<File> _authFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/indeed_auth.json');
  }

  Future<void> _clearSession() async {
    final cm = WebViewCookieManager();
    await cm.clearCookies();
    final f = await _authFile();
    if (await f.exists()) await f.delete();
  }

  Future<void> _loadSession() async {
    final f = await _authFile();
    if (await f.exists()) {
      try {
        final raw = await f.readAsString();
        final cookies = jsonDecode(raw);
        if (cookies is Map<String, dynamic>) {
          final kv = Map<String, String>.from(cookies);
          final cm = WebViewCookieManager();
          for (final entry in kv.entries) {
            await cm.setCookie(
              WebViewCookie(name: entry.key, value: entry.value, domain: 'kr.indeed.com', path: '/'),
            );
            await cm.setCookie(
              WebViewCookie(name: entry.key, value: entry.value, domain: 'secure.indeed.com', path: '/'),
            );
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _saveSession() async {
    try {
      final res = await _controller.runJavaScriptReturningResult('document.cookie');
      final cookieStr = res.toString().replaceAll('"', '');
      final parts = cookieStr.split(';');
      final map = <String, String>{};
      for (var p in parts) {
        final kv = p.split('=');
        if (kv.length >= 2) {
          map[kv[0].trim()] = kv[1].trim();
        }
      }
      if (map.isNotEmpty) {
        final f = await _authFile();
        await f.writeAsString(jsonEncode(map));
      }
    } catch (_) {}
  }

  Future<bool> _isLoggedIn() async {
    try {
      final res = await _controller.runJavaScriptReturningResult(
        '!!(document.querySelector(\'[data-tn-component="profileIcon"]\') || document.querySelector(\'a[href*="/account/logout"]\'))'
      );
      return res.toString() == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<bool> _isBlocked() async {
    try {
      final res = await _controller.runJavaScriptReturningResult(
        '(/just a moment|attention required|cloudflare|잠시만 기다리십시오/i.test(document.title) || /verify you are human|checking your browser/i.test(document.body.textContent))'
      );
      return res.toString() == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, String>> _extract() async {
    try {
      final js = await _controller.runJavaScriptReturningResult('''
        (() => {
          function g(s){
            const e = document.querySelector(s);
            return e ? e.textContent.trim().replace(/\\s+/g, " ") : "";
          }
          const ts = [
            "[data-testid=\\\"jobsearch-JobInfoHeader-title\\\"]", 
            ".jobsearch-JobInfoHeader-title", 
            "h1",
            ".jobsearch-JobInfoHeader-title-container h1"
          ];
          const cs = [
            "[data-testid=\\\"jobsearch-JobInfoHeader-companyName\\\"]", 
            ".jobsearch-JobInfoHeader-companyName", 
            ".jobsearch-InlineCompanyRating", 
            ".companyName",
            "[data-testid=\\\"inlineHeader-companyName\\\"]",
            ".jobsearch-CompanyReview--heading",
            ".jobsearch-JobInfoHeader-companyNameLink",
            "div.jobsearch-InlineCompanyRating > div:first-child"
          ];
          const ss = [
            "#salaryInfoAndJobType", 
            "[data-testid=\\\"jobsearch-JobInfoHeader-salary\\\"]", 
            "[data-testid=\\\"jobsearch-JobDetailsSection-salaryText\\\"]",
            ".jobsearch-JobMetadataHeader-item", 
            ".css-2iq1ht.eu4oa1w0",
            ".jobsearch-JobMetadataHeader-item.icon-container",
            "div.jobsearch-JobMetadataHeader-item",
            ".jobsearch-JobInfoHeader-salary-container",
            "div.jobsearch-JobDetailsSection-attributeContent",
            ".jobsearch-JobDetailsSection-attributeContent span"
          ];
          
          let jt = ""; for(const s of ts){ jt = g(s); if(jt) break; }
          let co = ""; for(const s of cs){ co = g(s); if(co) break; }
          
          let sl = ""; 
          for(const s of ss){ 
            const elements = document.querySelectorAll(s);
            for(const el of elements) {
              const txt = el.textContent.trim().replace(/\\s+/g, " ");
              if(txt && (txt.includes("원") || txt.includes("급") || txt.includes("봉") || txt.includes("Pay") || txt.includes("Salary"))) {
                sl = txt;
                break;
              }
            }
            if(sl) break;
          }

          // 최후의 수단: "월급", "연봉", "시급", "주급", "급여" 텍스트가 포함된 요소를 직접 찾기
          if(!sl){
            const allElements = document.querySelectorAll("div, span, p, li, b, strong");
            for(const el of allElements){
              const txt = el.textContent.trim();
              // 월급 2,500,000원 처럼 '원'이 붙어있는 경우도 포함하도록 수정
              if(/(월급|연봉|시급|주급|급여|Pay|Salary)\s*[:：]?\s*[\d,]+[원]?/i.test(txt)){
                sl = txt.replace(/\s+/g, " ");
                break;
              }
            }
          }
          
          return { jt, co, sl };
        })()
      ''');
      
      if (js is Map) {
        return {
          'jobTitle': (js['jt'] ?? '').toString(),
          'companyName': (js['co'] ?? '').toString(),
          'salary': (js['sl'] ?? '').toString(),
        };
      }
      
      // JSON 파싱 시도 (문자열로 반환된 경우)
      final raw = js.toString().replaceAll('\\\"', '"');
      final cleaned = raw.startsWith('"') && raw.endsWith('"') ? raw.substring(1, raw.length - 1) : raw;
      final m = jsonDecode(cleaned);
      return {
        'jobTitle': (m['jt'] ?? '').toString(),
        'companyName': (m['co'] ?? '').toString(),
        'salary': (m['sl'] ?? '').toString(),
      };
    } catch (_) {
      return {'jobTitle': '', 'companyName': '', 'salary': ''};
    }
  }

  Future<void> _start() async {
    setState(() {
      _loading = true;
      _status = '초기 세션 로드 중...';
    });
    await _loadSession();
    
    // 1. 로그인 여부 확인 및 로그인 페이지 이동
    setState(() => _status = '로그인 상태 확인 중...');
    await _controller.loadRequest(Uri.parse('https://secure.indeed.com/account/login?hl=ko_KR&co=KR'));
    await Future.delayed(const Duration(seconds: 3));
    
    var logged = await _isLoggedIn();
    if (!logged) {
      setState(() => _status = '로그인이 필요합니다. (자동 시도 중...)');
      await _clearSession();
      await _controller.loadRequest(Uri.parse('https://secure.indeed.com/account/login?hl=ko_KR&co=KR'));
      // 사용자가 직접 로그인하거나 리다이렉트를 기다릴 시간을 좀 더 줌
      await Future.delayed(const Duration(seconds: 4));
      logged = await _isLoggedIn();
    }
    
    // 2. 실제 공고 페이지로 이동
    setState(() => _status = '공고 페이지로 이동 중...');
    await _controller.loadRequest(Uri.parse(widget.targetUrl));
    
    Map<String, String> data = {'jobTitle': '', 'companyName': '', 'salary': ''};
    
    // 3. 차단 여부 확인 및 추출 시도 (최대 10번 반복)
    for (var i = 0; i < 10; i++) {
      final currentUrl = await _controller.currentUrl() ?? '';
      setState(() => _status = '페이지 로딩 대기 중... (${i + 1}/10)\n$currentUrl');
      
      await Future.delayed(const Duration(seconds: 2));
      
      final blocked = await _isBlocked();
      if (blocked) {
        setState(() => _status = '차단 해제 대기 중 (Cloudflare)...');
        continue;
      }

      // 공고 페이지에 도달했는지 확인 (URL에 viewjob이나 jk가 포함되어야 함)
      if (!currentUrl.contains('viewjob') && !currentUrl.contains('jk=')) {
        if (currentUrl.contains('login') || currentUrl.contains('account')) {
          setState(() => _status = '로그인 페이지에서 멈춰있습니다. 로그인이 필요할 수 있습니다.');
        }
        continue;
      }

      data = await _extract();
      if (data['jobTitle']!.isNotEmpty || data['companyName']!.isNotEmpty) {
        // 성공적으로 데이터를 찾으면 종료
        if (data['salary']!.isNotEmpty) {
          setState(() => _status = '추출 완료: ${data['salary']}');
          break;
        } else {
          setState(() => _status = '기본 정보는 찾았으나 급여를 찾는 중...');
        }
      }
    }
    
    await _saveSession();
    setState(() {
      _loading = false;
      _status = '${data['companyName'] ?? ''} | ${data['jobTitle'] ?? ''} | ${data['salary'] ?? ''}';
    });
    
    if (!mounted) return;
    
    // 데이터를 어느 정도 찾았으면 결과 반환
    if (data['jobTitle']!.isNotEmpty || data['companyName']!.isNotEmpty) {
      Navigator.of(context).pop(data);
    } else {
      setState(() => _status = '데이터를 추출하지 못했습니다. 화면을 확인해 주세요.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(_loading ? 'Loading' : 'Done'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(child: WebViewWidget(controller: _controller)),
          SizedBox(
            height: 48,
            child: Center(child: Text(_status)),
          ),
        ],
      ),
    );
  }
}
