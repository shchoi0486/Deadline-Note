import 'dart:async';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:http/http.dart' as http;

class CompanyInfo {
  final String summary;
  final String newsSummary;
  final String businessDirection;
  final String jobConnection;
  final String riskPoints;
  final List<String> keywords;
  final List<String> news;
  final List<String> sourceUrls;

  CompanyInfo({
    required this.summary,
    required this.newsSummary,
    required this.businessDirection,
    required this.jobConnection,
    required this.riskPoints,
    required this.keywords,
    required this.news,
    required this.sourceUrls,
  });
}

class CompanyInfoService {
  /// 긴 채용공고명에서 핵심 기업명/검색어만 추출하는 헬퍼 함수
  static String _extractCoreName(String input) {
    String res = input.replaceAll(RegExp(r'[\(（][\s]*[주유사재복의학특합][\s]*[\)）]'), '').replaceAll('㈜', '');
    res = res.replaceAll(RegExp(r'[\(（][\s]*주식회사[\s]*[\)）]'), '');
    res = res.replaceAll(RegExp(r'주식회사[\s]+'), '');
    res = res.replaceAll(RegExp(r'[\s]+주식회사'), '');
    res = res.replaceAll(RegExp(r'유한회사[\s]+|[\s]+유한회사'), '');
    res = res.replaceAll(RegExp(r'[\[【].*?[\]】]'), ' ');
    res = res.replaceAll(RegExp(r'(채용|모집|신입|경력|사원|인턴|공고|직무|담당자|매니저|부문|전형|지원|개발자)'), ' ');
    res = res.replaceAll(RegExp(r'[-_:/|,\(\)（）]'), ' ');
    res = res.trim().replaceAll(RegExp(r'\s+'), ' ');
    
    List<String> words = res.split(' ');
    if (words.length > 2) {
      res = words.take(2).join(' ');
    }
    if (res.isEmpty) return input.split(' ').first;
    return res;
  }

  /// 웹 검색 및 AI(규칙 기반) 분석
  static Future<CompanyInfo> fetchCompanyInfo(String companyName) async {
    final coreName = _extractCoreName(companyName);
    final List<String> searchKeywords = coreName.split(' ').where((w) => w.length >= 2).toList();
    if (searchKeywords.isEmpty) searchKeywords.add(coreName);

    try {
      // 💡 [개선] 너무 긴 검색어를 줄여 검색 결과 노출 확률을 대폭 높임
      final List<Map<String, String>> searchConfigs =[
        {'type': 'news', 'query': coreName, 'where': 'news'},
        {'type': 'news', 'query': '$coreName 실적', 'where': 'news'},
        {'type': 'biz', 'query': '$coreName 사업 전략', 'where': 'news'}, 
        {'type': 'biz', 'query': '$coreName 미래 성장', 'where': 'view'}, 
        {'type': 'biz', 'query': '$coreName 목표', 'where': 'news'},
        {'type': 'recruit', 'query': '$coreName 채용 인재상', 'where': 'view'}, 
        {'type': 'recruit', 'query': '$coreName 직무 인터뷰', 'where': 'view'}, 
        {'type': 'recruit', 'query': '$coreName 조직문화 복지', 'where': 'view'},
        {'type': 'risk', 'query': '$coreName 경쟁사 점유율', 'where': 'news'}, 
        {'type': 'risk', 'query': '$coreName 위기 리스크', 'where': 'news'},
        {'type': 'risk', 'query': '$coreName 단점 아쉬운 점', 'where': 'view'}, 
      ];

      Map<String, List<String>> categorizedData = {
        'news': [], 'biz': [], 'recruit':[], 'risk': [], 'common':[],
      };
      Set<String> collectedUrls = {};

      final now = DateTime.now();
      final oneYearAgo = now.subtract(const Duration(days: 365));
      String formatDate(DateTime d) => '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
      String formatNso(DateTime d) => '${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}';
      
      final String endDate = formatDate(now);
      final String startDate = formatDate(oneYearAgo);
      // 💡 [개선] 네이버 뉴스 1년치 검색을 완벽하게 동작하게 하는 nso 파라미터 추가
      final String nsoParam = 'so:r,p:from${formatNso(oneYearAgo)}to${formatNso(now)},a:all';

      await Future.wait(searchConfigs.map((config) async {
        final where = config['where']!;
        String searchUrl;
        
        if (where == 'news') {
          // sort=1(최신순) 대신 sort=0(관련도순)을 사용하여 쓰레기 기사 방지
          searchUrl = 'https://search.naver.com/search.naver?where=news&query=${Uri.encodeComponent(config['query']!)}&sort=0&pd=3&ds=$startDate&de=$endDate&nso=$nsoParam';
        } else if (where == 'view') {
          searchUrl = 'https://search.naver.com/search.naver?where=view&query=${Uri.encodeComponent(config['query']!)}&qdt=1';
        } else {
          searchUrl = 'https://search.naver.com/search.naver?query=${Uri.encodeComponent(config['query']!)}';
        }
            
        try {
          final response = await http.get(Uri.parse(searchUrl), headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9',
            'Referer': 'https://www.naver.com',
          }).timeout(const Duration(seconds: 8));

          if (response.statusCode == 200) {
            final document = html_parser.parse(response.body);
            final List<String> rawTexts =[];
            
            document.querySelectorAll('.news_tit, .lnk_tit, .total_tit, .api_txt_lines.title,[class*="headline"], .sds-comps-text-type-headline1').forEach((e) {
              final text = e.text.trim();
              if (text.isEmpty || text.contains('function(') || text.contains('window.')) return;

              bool hasKeyword = searchKeywords.any((kw) => text.toLowerCase().contains(kw.toLowerCase()));
              if (!hasKeyword) return;

              final safeText = text.replaceAll('[', '').replaceAll(']', '');
              String? url = e.attributes['href'] ?? e.parent?.attributes['href'] ?? e.querySelector('a')?.attributes['href'];
              
              if (url != null && url.startsWith('http')) {
                collectedUrls.add(url);
                rawTexts.add('[$safeText]($url)');
              } else {
                rawTexts.add(safeText);
              }
            });

            document.querySelectorAll('.api_txt_lines, .api_txt_lines.dsc, .total_dsc, .view_wrap .dsc_txt, [class*="body"], .sds-comps-text-type-body1, .news_dsc, .dsc_txt').forEach((e) {
              String text = e.text.trim();
              if (text.isEmpty || text.toLowerCase().contains('function(') || text.contains('window.')) return;

              text = text.replaceAll(RegExp(r'<[^>]*>'), ' '); 
              text = text.replaceAll(RegExp(r'&[a-zA-Z0-9#]+;'), ' '); 
              text = text.replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}'), '');
              text = text.replaceAll(RegExp(r'\d{2,3}-\d{3,4}-\d{4}'), '');
              text = text.replaceAll(RegExp(r'\.{2,}'), ' ').replaceAll('…', ' ');
              
              final sentences = text.split(RegExp(r'(?<=[.?!])\s+'));
              
              for (var sentence in sentences) {
                 var cleaned = sentence.replaceAll(RegExp(r'\s+'), ' ').trim();
                 cleaned = cleaned.replaceAll(RegExp(r'^(\[.*?\]|\(.*?\)|\d{4}\.\d{2}\.\d{2}\.?)\s*'), '').trim();
                 cleaned = cleaned.replaceAll(RegExp(r'^(사진|제공|출처|글|취재|정리|자료|도표|포토)=.*?(기자|특파원|교수|연구원)?\s*'), '').trim();
                 
                 if (cleaned.length < 12) continue; 
                 
                 cleaned = cleaned.replaceAll(RegExp(r'^["“”]'), '').replaceAll(RegExp(r'["“”]$'), '').trim();
                 cleaned = cleaned.replaceAll(RegExp(r'^(이어|또한|반면|한편|특히|다만|아울러|더불어|따라서|이에|이와 함께|이날|이후|직후|앞서|현재|지난해|올해|최근|그리고|하지만|그러나|그런데|게다가|동시에|반면에|그렇지만|그럼에도|불구하고|결국|드디어|마침내|물론|사실|실제|실제로|무엇보다|우선|먼저|다음으로|마지막으로)\s+'), '').trim();
                 
                 if (RegExp(r'^(\d+[\.\)\]]|과정|단계|순서|개요|연혁|목차)\s*').hasMatch(cleaned)) continue;
                 if (cleaned.contains('1) 개요') || cleaned.contains('2) 연혁')) continue;
                 if (RegExp(r'(을|를|은|는|이|가|로|으로|와|과|의|도|에|에게|께|한테|더러|보고|부터|까지|마저|조차|이라도|이나|이나마)\s*$').hasMatch(cleaned)) continue;

                 bool hasKeyword = searchKeywords.any((kw) => cleaned.toLowerCase().contains(kw.toLowerCase()));
                 if (!hasKeyword) continue;

                 String? url = e.attributes['href'] ?? e.parent?.attributes['href'] ?? e.querySelector('a')?.attributes['href'];
                 if (url != null && url.startsWith('http')) {
                   collectedUrls.add(url);
                   rawTexts.add('$cleaned [Source]($url)');
                 } else {
                   rawTexts.add(cleaned);
                 }
              }
            });
            
            for (var text in rawTexts) {
              if (text.isEmpty) continue;
              final cleanText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
              
              if (_isValidText(cleanText, coreName)) {
                // 💡 [핵심 개선] 하나의 텍스트가 여러 카테고리(뉴스, 비즈니스 등)에 중복 소속될 수 있도록 허용
                Set<String> targetCategories = {config['type']!}; // 기존 type 무조건 보존
                final lowerText = cleanText.toLowerCase();
                
                bool isRecruit = lowerText.contains('채용') || lowerText.contains('인재') || lowerText.contains('역량') || lowerText.contains('모집') || 
                                 lowerText.contains('면접') || lowerText.contains('자소서') || lowerText.contains('직무') || lowerText.contains('문화') ||
                                 lowerText.contains('복지') || lowerText.contains('워라밸') || lowerText.contains('조직') || lowerText.contains('지원동기') || lowerText.contains('포부');
                bool isRisk = lowerText.contains('적자') || lowerText.contains('감소') || lowerText.contains('하락') || lowerText.contains('둔화') || 
                              lowerText.contains('규제') || lowerText.contains('논란') || lowerText.contains('위기') || lowerText.contains('소송') || 
                              lowerText.contains('우려') || lowerText.contains('부진') || lowerText.contains('리스크') || lowerText.contains('경쟁사');
                bool isBiz = lowerText.contains('전략') || lowerText.contains('비전') || lowerText.contains('목표') || lowerText.contains('확장') || 
                             lowerText.contains('진출') || lowerText.contains('개발') || lowerText.contains('사업') || lowerText.contains('투자') || 
                             lowerText.contains('매출') || lowerText.contains('실적') || lowerText.contains('영업이익') || lowerText.contains('흑자') || 
                             lowerText.contains('성장') || lowerText.contains('수주') || lowerText.contains('협력') || lowerText.contains('m&a') || lowerText.contains('점유율');

                if (isRecruit) targetCategories.add('recruit');
                if (isRisk) targetCategories.add('risk');
                if (isBiz) targetCategories.add('biz');

                // 💡 [블로그 스팸 방지] 자소서 문항 팁이 비즈니스나 뉴스로 분류되는 것 철저히 차단
                if (lowerText.contains('작성해야') || lowerText.contains('작성법') || lowerText.contains('자소서 문항') || lowerText.contains('작성해보세요')) {
                   targetCategories.remove('biz');
                   targetCategories.remove('news');
                   targetCategories.remove('risk');
                   targetCategories.add('recruit');
                }

                for (String cat in targetCategories) {
                  if (!categorizedData[cat]!.contains(cleanText)) {
                    categorizedData[cat]!.add(cleanText);
                  }
                }
              }
            }
          }
        } catch (e) {
          // 개별 요청 실패 시 무시
        }
      }));

      // Fallback 처리
      if (categorizedData.values.every((list) => list.isEmpty)) {
        try {
          final fallbackUrl = 'https://search.naver.com/search.naver?where=news&query=${Uri.encodeComponent(coreName)}&sort=0';
          final response = await http.get(Uri.parse(fallbackUrl), headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          }).timeout(const Duration(seconds: 5));

          if (response.statusCode == 200) {
            final document = html_parser.parse(response.body);
            document.querySelectorAll('.news_tit').forEach((e) {
              final text = e.text.trim();
              if (text.isEmpty) return;
              
              bool hasKeyword = searchKeywords.any((kw) => text.toLowerCase().contains(kw.toLowerCase()));
              if (!hasKeyword) return;

              if (_isValidText(text, coreName)) {
                 categorizedData['news']!.add(text);
              }
            });
          }
        } catch (e) {
          // Fallback 실패 시 무시
        }
      }

      if (categorizedData.values.every((list) => list.isEmpty)) {
        return CompanyInfo(
          summary: '[$coreName] 관련 최근 1년 내 유의미한 정보를 찾을 수 없습니다.',
          newsSummary: '• 최근 1년 내 분석 가능한 뉴스 데이터가 없습니다.\n• 하단의 포털 검색 버튼을 활용해 보세요.',
          businessDirection: '• 사업 정보 로딩 실패',
          jobConnection: '• 채용 정보 로딩 실패',
          riskPoints: '• 리스크 정보 로딩 실패',
          keywords: ['#정보부족'],
          news:['정보를 찾을 수 없습니다.'],
          sourceUrls:[],
        );
      }

      final allTexts = categorizedData.values.expand((x) => x).toList();
      final keywords = _generateDynamicKeywords(coreName, allTexts);

      return CompanyInfo(
        summary: _generateDetailedSummary(coreName, categorizedData, keywords),
        newsSummary: _generateNewsSummary(coreName, categorizedData['news'] ??[]),
        businessDirection: _generateBusinessDirection(coreName, categorizedData['biz'] ??[], keywords),
        jobConnection: _generateJobConnection(coreName, categorizedData['recruit'] ??[], keywords),
        riskPoints: _generateRiskPoints(coreName, categorizedData['risk'] ??[], keywords),
        keywords: keywords,
        news: _removeDuplicates(categorizedData['news'] ??[]).take(3).toList(),
        sourceUrls: collectedUrls.take(10).toList(),
      );
    } catch (e) {
      return CompanyInfo(
        summary: '서버 통신 중 오류가 발생했습니다. 잠시 후 다시 시도해주세요.',
        newsSummary: '• 로딩 실패',
        businessDirection: '• 로딩 실패',
        jobConnection: '• 로딩 실패',
        riskPoints: '• 로딩 실패',
        keywords: ['#검색오류'],
        news: ['정보 로딩 실패'],
        sourceUrls:[],
      );
    }
  }

  static List<String> _removeDuplicates(List<String> texts) {
    final uniqueTexts = <String>[];
    for (var text in texts) {
      bool isDuplicate = false;
      for (int i = 0; i < uniqueTexts.length; i++) {
        if (_calculateSimilarity(text, uniqueTexts[i]) > 0.6) {
          isDuplicate = true;
          if (text.length > uniqueTexts[i].length) uniqueTexts[i] = text;
          break;
        }
      }
      if (!isDuplicate) uniqueTexts.add(text);
    }
    return uniqueTexts;
  }

  static double _calculateSimilarity(String s1, String s2) {
    String c1 = s1.replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '').trim();
    String c2 = s2.replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '').trim();
    if (c1 == c2) return 1.0;
    if (c1.contains(c2) || c2.contains(c1)) return 0.9; 
    Set<String> t1 = c1.split(' ').where((w) => w.length > 1).toSet();
    Set<String> t2 = c2.split(' ').where((w) => w.length > 1).toSet();
    if (t1.isEmpty || t2.isEmpty) return 0.0;
    return t1.intersection(t2).length / t1.union(t2).length;
  }

  static bool _isValidText(String text, String companyName) {
    final textWithoutLink = text.replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '').trim();
    if (textWithoutLink.length < 8 || textWithoutLink.length > 800) return false; 
    
    if (textWithoutLink.contains('http') || textWithoutLink.contains('www.') || textWithoutLink.contains('.co.kr') || textWithoutLink.contains('.com')) return false;
    
    // 💡 [개선] 블로그의 단순 취업 안내글/스팸 키워드 완벽 차단
    final junkKeywords =[
      '투자의견', '목표가', '순매수', '외국인', '대법원', '파업', '가처분', '별세', '부고', 
      '아파트', '부동산', '분양', '로그인', '회원가입', '마이페이지', '전체메뉴', '바로가기', '통합검색',
      '관련기사', '구독하기', '무단전재', '재배포 금지', 'ⓒ', 'Copyright', 'All rights reserved',
      '코치님', '수강생', '다수 배출', '오픈카톡', '자소서 첨삭', '멘토링', 'OOOO',
      '서이추', '이웃환영', '포스팅', '더라고요', '뒤적거려', '더라', 'ㅎㅎ', 'ㅋㅋ', 'ㅠㅠ',
      '클릭', '링크', '홈페이지', '사이트', '주소', '문의', '상담', '전화', '이메일', '팩스',
      '좋아요', '알림설정', '더보기', '기자', '특파원', '기자입니다',
      '작성해야', '작성해보세요', '작성법', '바랍니다', '공유해드립니다' // 자소서 문항 스팸 방지
    ];
    if (junkKeywords.any((k) => textWithoutLink.contains(k))) return false;

    final commaCount = textWithoutLink.split(',').length - 1;
    if (commaCount >= 8) return false;

    if (textWithoutLink.contains('"') && !textWithoutLink.contains(' "')) {
       final quoteCount = textWithoutLink.split('"').length - 1;
       if (quoteCount % 2 != 0) return false; 
    }

    return true;
  }

  static String _generateNewsSummary(String name, List<String> texts) {
    if (texts.isEmpty) return '• 최근 1년 내 분석 가능한 뉴스 데이터가 없습니다.\n• 하단의 포털 검색 버튼을 활용해 보세요.';
    final uniqueSelected = _removeDuplicates(texts);
    uniqueSelected.sort((a, b) {
      final aScore = (a.contains('실적') ? 1 : 0) + (a.contains('계약') ? 1 : 0) + (a.contains('출시') ? 1 : 0);
      final bScore = (b.contains('실적') ? 1 : 0) + (b.contains('계약') ? 1 : 0) + (b.contains('출시') ? 1 : 0);
      return bScore.compareTo(aScore);
    });
    return uniqueSelected.take(8).map((s) => '• $s').join('\n');
  }

  static String _generateBusinessDirection(String name, List<String> texts, List<String> keywords) {
    var strategies = texts.where((t) => 
      t.contains('목표') || t.contains('계획') || t.contains('전략') || t.contains('비전') || t.contains('확대') || t.contains('진출') ||
      t.contains('체결') || t.contains('수주') || t.contains('공급') || t.contains('개발') ||
      t.contains('사업') || t.contains('분야') || t.contains('제품') || t.contains('서비스') ||
      t.contains('투자') || t.contains('M&A') || t.contains('인수') || t.contains('통합') || t.contains('혁신') ||
      t.contains('구축') || t.contains('도입') || t.contains('적용') || t.contains('강화') || t.contains('추진') || t.contains('성장')
    ).toList();
    
    strategies = _removeDuplicates(strategies);
    strategies.sort((a, b) {
      final aScore = (a.contains('원') ? 2 : 0) + (a.contains('달러') ? 2 : 0) + 
                     (a.contains('계약') ? 1 : 0) + (a.contains('수주') ? 1 : 0) + 
                     (a.contains('전략') ? 2 : 0) + (a.contains('성장') ? 1 : 0);
      final bScore = (b.contains('원') ? 2 : 0) + (b.contains('달러') ? 2 : 0) + 
                     (b.contains('계약') ? 1 : 0) + (b.contains('수주') ? 1 : 0) + 
                     (b.contains('전략') ? 2 : 0) + (b.contains('성장') ? 1 : 0);
      return bScore.compareTo(aScore);
    });

    if (strategies.isNotEmpty) {
      return strategies.take(8).map((s) => '• $s').join('\n');
    } else {
      final keyStr = keywords.where((k) => !['#최근', '#정보', '#확인'].contains(k)).take(5).join(' ');
      return '• 최근 1년 내 구체적인 사업 전략 문장을 찾지 못했습니다.\n• 관련 키워드: $keyStr\n• (Tip) 기업 홈페이지의 IR 자료나 뉴스룸에서 최신 전략을 확인해 보세요.';
    }
  }

  static String _generateJobConnection(String name, List<String> texts, List<String> keywords) {
    final buffer = StringBuffer();
    var requirements = texts.where((t) => 
      t.contains('우대') || t.contains('경험') || t.contains('능력') || t.contains('역량') || t.contains('활용') || t.contains('사용') ||
      t.contains('인재') || t.contains('문화') || t.contains('인터뷰') || t.contains('조언') || t.contains('합격') ||
      t.contains('자격') || t.contains('필수') || t.contains('업무') || t.contains('담당') || t.contains('복지') || t.contains('워라밸')
    ).toList();
    
    requirements = _removeDuplicates(requirements);
    final selectedRequirements = requirements.take(8).toList();

    if (selectedRequirements.isNotEmpty) {
      for (var req in selectedRequirements) {
        buffer.writeln('• $req');
      }
    } else {
        var idealPersona = texts.where((t) => 
            t.contains('인재') || t.contains('소통') || t.contains('협업') || t.contains('도전') || t.contains('전문성') || t.contains('창의') ||
            t.contains('주도') || t.contains('열정') || t.contains('성장') || t.contains('태도')
        ).toList();
        idealPersona = _removeDuplicates(idealPersona);
        final selectedPersona = idealPersona.take(5).toList();
        if (selectedPersona.isNotEmpty) {
          for (var persona in selectedPersona) {
              buffer.writeln('• $persona');
          }
        } else {
          buffer.writeln('• 해당 기업의 구체적인 채용 특징을 찾지 못했습니다. 일반적인 직무 역량을 중심으로 준비하세요.');
        }
    }

    buffer.writeln('\n**💡 AI 자소서/면접 팁**');
    
    bool addedTip = false;
    final keywordStr = keywords.join(' ');
    if (keywordStr.contains('기술') || keywordStr.contains('개발') || keywordStr.contains('AI') || keywordStr.contains('데이터') || keywordStr.contains('시스템')) {
      buffer.writeln('• [R&D/기술] 최신 기술 트렌드 및 프로젝트 문제 해결(Troubleshooting) 경험을 어필하세요.');
      addedTip = true;
    }
    if (keywordStr.contains('고객') || keywordStr.contains('서비스') || keywordStr.contains('플랫폼') || keywordStr.contains('마케팅')) {
      buffer.writeln('• [서비스/기획] 고객 니즈 분석 및 데이터 기반 의사결정 역량을 강조하세요.');
      addedTip = true;
    }
    if (keywordStr.contains('글로벌') || keywordStr.contains('해외') || keywordStr.contains('시장') || keywordStr.contains('수출')) {
      buffer.writeln('• [글로벌] 어학 능력 및 해당 문화권/시장에 대한 높은 이해도를 구체적으로 언급하세요.');
      addedTip = true;
    }
    if (keywordStr.contains('영업') || keywordStr.contains('판매') || keywordStr.contains('유통')) {
      buffer.writeln('• [영업/영업관리] 목표 달성 의지와 대인 관계 구축 능력을 구체적인 성공 사례로 보여주세요.');
      addedTip = true;
    }
    
    if (!addedTip) {
      buffer.writeln('• [공통] 소통과 협업을 통해 조직 내에서 목표를 달성하거나 갈등을 해결한 구체적인 사례를 준비해 보세요.');
    }
    
    return buffer.toString().trim();
  }

  static String _generateRiskPoints(String name, List<String> texts, List<String> keywords) {
    var risks = texts.where((t) => 
      t.contains('적자') || t.contains('감소') || t.contains('하락') || t.contains('둔화') || t.contains('규제') || t.contains('경쟁') ||
      t.contains('우려') || t.contains('부진') || t.contains('축소') || t.contains('불확실') || t.contains('지연') ||
      t.contains('라이벌') || t.contains('대비') || t.contains('격차') || t.contains('위협') || t.contains('퇴출') ||
      t.contains('논란') || t.contains('소송') || t.contains('과징금') || t.contains('침체') || t.contains('부정적')
    ).toList();
    
    risks = _removeDuplicates(risks);

    final positiveWords =['유리', '확대', '기회', '수혜', '긍정', '상승', '성장', '개선', '돌파', '해결', '1위', '성공'];
    risks = risks.where((text) {
      return !positiveWords.any((pw) => text.contains(pw));
    }).toList();

    if (risks.isNotEmpty) {
      final summaryList = risks.take(8).map((s) => '• $s').join('\n');
      return '$summaryList\n\n**💡 면접 대비 리스크 방어 팁**\n• 위 산업/기업 이슈에 대해 본인만의 해결 방안이나 긍정적 관점(기회 요소)을 미리 고민해 보세요.';
    } else {
      if (keywords.isNotEmpty) {
        final marketKeywords = keywords.where((k) => k.length > 2 && !['#최근', '#정보'].contains(k)).take(5).join(', ');
        return '• 최근 1년 내 특이한 리스크 요인이 발견되지 않았습니다.\n• 참고 시장 키워드: $marketKeywords\n• (Tip) 부정적 이슈가 없다면, 경쟁사 동향이나 산업 전반의 잠재 위기 요인을 파악해 보세요.';
      }
      return '• 뚜렷한 리스크 요인이 검색되지 않았습니다. 업계 전반의 이슈를 포털을 통해 추가로 확인해 보세요.';
    }
  }

  static String _generateDetailedSummary(String name, Map<String, List<String>> data, List<String> keywords) {
    final totalCount = data.values.fold(0, (prev, list) => prev + list.length);
    final topKeywords = keywords.take(5).join(' ');
    
    String countInfo = '';
    if (totalCount > 20) {
      countInfo = '총 ${totalCount}개의 핵심 데이터를 수집하여 분석했습니다. ';
    } else if (totalCount > 0) {
      countInfo = '수집된 데이터를 바탕으로 기업의 현황을 요약했습니다. ';
    }

    return '최근 1년 간의 $name 관련 소식을 심층 분석했습니다.\n$countInfo\n핵심 키워드: $topKeywords';
  }

  static List<String> _generateDynamicKeywords(String name, List<String> texts) {
    final Map<String, int> freq = {};
    
    final stopWords = {
      '최근', '글로벌', '공정기술', '마크', 'mark', '기반', '중심', '등을', '등이', '등은',
      '대해', '관련', '위한', '통해', '함께', '밝혀', '출시', '이번', '지난', '올해', '내년', '기존',
      '확대', '강화', '선정', '최초', '연속', '돌파', '달성', '공개', '선보여', '나서', '추진', '본격',
      '속도', '탄력', '박차', '기대', '전망', '분석', '확인', '최대', '최고', '주요', '기업', '사업',
      '브랜드', '시장', '분야', '서비스', '제공', '뉴스', '기자', '연합뉴스', '뉴시스', '머니투데이',
      '네이버', '다음', '검색', '결과', '통합', '섹션', '영역', '바로가기', '상단', '하단', '오전', '오후',
      '현재', '거래', '체결', '채용', '모집', '지원', '공고', '자소서', '자기소개서', '면접', '합격',
      '메모', '기록', '작성', '수정', '삭제', '등록', '확인', '취소', '완료', '성공', '실패',
      '싶은', '원하는', '필요한', '가능한', '다양한', '모든', '많은', '적은', '높은', '낮은',
      '매우', '가장', '특히', '더욱', '그대로', '이미', '벌써', '다시', '자주', '가끔',
      '지난해', '내일', '어제', '오늘', '직무', '추진하고', '공개한', '밝힌', '알린', '전한',
      '대비', '기록한', '나타난', '보인', '나온', '가진', '넘는', '미치는', '따르면', '의하면',
      '어떤', '이런', '저런', '같은', '경우', '대한', '있는', '입니다', '합니다', '이다', '며', '고', '다',
      '있다', '있습니다', '있고', '있어', '있음', '없다', '없습니다', '없고', '없어', '없는', '없음',
      '된다', '됩니다', '되고', '되어', '되는', '됨', '한다', '하고', '하여', '하는', '함',
      '이다', '입니다', '이고', '이며', '이라는', '이란', '아닌', '아니다', '아니라',
      '것이다', '것입니다', '것으로', '위해', '위한', '통해', '통한', '대해', '대한', '관해', '관한',
      '가장', '매우', '특히', '더욱', '많이', '많은', '모두', '모든', '일부', '다른', '같은',
      '이런', '저런', '그런', '어떤', '어떻게', '무엇을', '무엇이',
      '경우', '때문', '정도', '부분', '사실', '내용', '이번', '다음', '이전', '이후',
      '오전', '오후', '하루', '이번주', '다음주', '지난주', '개월', '년', '월', '일', '시', '분', '초',
      '만원', '억원', '조원', '달러', '퍼센트', '기자', '보도', '소식', '발표',
      '사진', '제공', '출처', '자료', '말했다', '밝혔다', '전했다', '알렸다', '강조했다', '설명했다', '덧붙였다',
      '주장했다', '보인다', '보였다', '나타났다', '기록했다', '차지했다', '달성했다',
      '예정이다', '계획이다', '목표다', '전망이다', '가능성', '필요성', '중요성',
      '문제', '해결', '방안', '대책', '영향', '결과', '원인', '이유',
      '수준', '규모', '비중', '추이', '평균', '중간', '중심',
      '관련', '관계', '사이', '방식', '방법', '수단', '효과', '효율', '성능',
      '기능', '역할', '책임', '의미', '가치', '평가', '인식', '판단', '결정',
      '선택', '집중', '노력', '준비', '시작', '종료', '진행', '완료',
      '확인', '발견', '유지', '보수', '개선', '혁신', '변화', '발전', '대부분'
    };

    final enStopWords = {
      'MARK', 'GREAT', 'WORK', 'PLACE', 'GRE', 'GWP', 'THE', 'AND', 'FOR', 'NEW', 'BEST', 'TOP',
      'COMPANY', 'THAT', 'THIS', 'WITH', 'YOU', 'YOUR', 'HTTP', 'COM', 'WWW'
    };

    for (var text in texts) {
      final plainText = text.replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '');
      final rawWords = plainText.replaceAll(RegExp(r'[^가-힣a-zA-Z0-9\s]'), ' ').split(RegExp(r'\s+'));

      for (var rawWord in rawWords) {
        String word = rawWord;
        
        if (word.toLowerCase().contains(name.toLowerCase())) continue;
        if (RegExp(r'^\d+$').hasMatch(word)) continue;

        final suffixes =[
          '하고', '하는', '합니다', '했습니다', '했다', '해', '하여',
          '되고', '되는', '됩니다', '됐습니다', '됐다', '돼', '되어',
          '있는', '있습니다', '있다', '있고', '있음',
          '없는', '없습니다', '없다', '없고', '없음',
          '이다', '입니다', '이고', '이며',
          '아닌', '아니다', '아니고',
          '스러운', '스럽게',
          '에서', '에게', '으로', '로', '까지', '부터', '보다', '마저', '조차', '이나',
          '의', '에', '을', '를', '은', '는', '이', '가', '와', '과', '도'
        ];

        for (var suffix in suffixes) {
          if (word.endsWith(suffix) && word.length > suffix.length) {
            word = word.substring(0, word.length - suffix.length);
            break; 
          }
        }

        if (word.length < 2) continue; 
        
        if (RegExp(r'^[a-zA-Z]+$').hasMatch(word)) {
           final wUpper = word.toUpperCase();
           if (wUpper.length <= 2 && wUpper != 'AI' && wUpper != 'IT' && wUpper != 'DX') continue;
           if (enStopWords.contains(wUpper)) continue;
           freq[wUpper] = (freq[wUpper] ?? 0) + 1;
        } else {
           if (stopWords.contains(word)) continue;
           freq[word] = (freq[word] ?? 0) + 1;
        }
      }
    }

    final sortedKeywords = freq.entries.toList()
      ..sort((a, b) {
        int cmp = b.value.compareTo(a.value);
        if (cmp == 0) return b.key.length.compareTo(a.key.length);
        return cmp;
      });

    final result = sortedKeywords.take(10).map((e) => '#${e.key}').toList();
    
    if (result.length < 3) {
      result.addAll(['#성장동력', '#조직문화', '#비전'].take(3 - result.length));
    }
    return result;
  }
}