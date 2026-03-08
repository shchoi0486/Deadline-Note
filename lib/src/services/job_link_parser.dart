import 'dart:convert';

import 'package:charset_converter/charset_converter.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/job_site.dart';
import '../models/deadline_type.dart';
import 'parsers/base_job_parser.dart';
import 'parsers/kr_job_parser.dart';
import 'parsers/global_job_parser.dart';
import 'parsers/jp_job_parser.dart';
import 'parsers/cn_job_parser.dart';
import 'parsers/in_job_parser.dart';

class ParsedJobLink {
  ParsedJobLink({
    required this.url,
    required this.site,
    required this.companyName,
    required this.jobTitle,
    required this.deadlineAt,
    required this.deadlineType,
    required this.salary,
    required this.warnings,
    this.isEstimated = false,
  });

  final Uri url;
  final JobSite site;
  final String companyName;
  final String jobTitle;
  final DateTime? deadlineAt;
  final DeadlineType deadlineType;
  final String salary;
  final List<String> warnings;
  final bool isEstimated;
}

// Input DTO for compute
class _ParseInput {
  final String html;
  final String url;
  final String? contextText;
  _ParseInput(this.html, this.url, this.contextText);
}

typedef _PartialJobData = PartialJobData;

// Top-level function for compute
ParsedJobLink _parseHtmlContent(_ParseInput input) {
  final uri = Uri.parse(input.url);
  final document = html_parser.parse(input.html);
  final contextText = input.contextText?.trim() ?? '';

  String? metaProperty(String property) {
    return document
        .querySelector('meta[property="$property"]')
        ?.attributes['content']
        ?.trim();
  }

  String? metaName(String name) {
    return document
        .querySelector('meta[name="$name"]')
        ?.attributes['content']
        ?.trim();
  }

  final ogTitle = metaProperty('og:title');
  final title =
      ogTitle?.isNotEmpty == true ? ogTitle! : (document.querySelector('title')?.text.trim() ?? '');

  final ogDescription = metaProperty('og:description');
  final description = ogDescription?.isNotEmpty == true ? ogDescription! : (metaName('description') ?? '');
  final writer = metaName('writer') ?? '';
  final ogSiteName = metaProperty('og:site_name') ?? '';

  final site = _detectSite(uri: uri, ogSiteName: ogSiteName, title: title);

  // [수정] Indeed 차단 감지 및 처리 (최우선 순위로 이동)
  if (site == JobSite.indeed) {
    // 1. HTTP 상태 코드가 403인 경우 (이미 호출부에서 처리되지만, 여기서도 다시 체크)
    // 2. HTML 내용 기반 차단 감지
    final isBlocked = _isIndeedBlockedDocument(
            title: title,
            description: description,
            bodyText: document.body?.text ?? '') ||
        _looksLikeIndeedBlockedPage(document.outerHtml) ||
        title.toLowerCase().contains('just a moment') ||
        title.toLowerCase().contains('attention required') ||
        title.toLowerCase() == 'title';

    if (isBlocked) {
      var company = '';
      var jobTitle = '';

      if (contextText.isNotEmpty) {
        // Indeed 앱 공유 텍스트 패턴 우선 처리
        final rawLines = contextText
            .split(RegExp(r'[\r\n]+'))
            .map((l) => l.trim())
            .where((l) => l.isNotEmpty)
            .toList();

        final lines = rawLines.where((l) => !l.toLowerCase().contains('http')).toList();

        if (lines.isNotEmpty) {
          final firstLine = lines[0];
          // "Indeed에서 이 채용 공고를 확인해 보세요" 패턴
          if (firstLine.contains('Indeed에서 이 채용 공고를 확인해 보세요') || 
              firstLine.contains('Check out this job at')) {
            if (lines.length >= 3) {
              // 패턴: 
              // Indeed에서 이 채용 공고를 확인해 보세요
              // Job Title
              // Company Name
              jobTitle = lines[1];
              company = _cleanCompanyName(lines[2]);
            } else if (lines.length == 2) {
              jobTitle = lines[1];
            }
          } else {
            // 다른 일반적인 패턴 시도
            final fallback = _extractTitleCompanyFromContextText(contextText);
            company = _cleanCompanyName(fallback.companyName);
            jobTitle = fallback.jobTitle;
          }
        }
      }

      // 여전히 비어있으면 전체 텍스트에서 재시도
      if (company.isEmpty || jobTitle.isEmpty) {
        final fallback = _extractTitleCompanyFromContextText(contextText);
        if (company.isEmpty) company = _cleanCompanyName(fallback.companyName);
        if (jobTitle.isEmpty) jobTitle = fallback.jobTitle;
      }

      // 차단 페이지의 타이틀("Just a moment...")이 들어가지 않도록 최종 방어
      if (jobTitle.toLowerCase().contains('just a moment') ||
          jobTitle.toLowerCase().contains('attention required') ||
          jobTitle.toLowerCase() == 'title') {
        jobTitle = '';
      }
      if (company.toLowerCase() == 'title' || company.toLowerCase().contains('indeed')) {
        company = '';
      }

      final warnings = <String>[];
      if (company.isEmpty) warnings.add('parseWarningCompany');
      if (jobTitle.isEmpty) warnings.add('parseWarningTitle');
      if (company.isEmpty || jobTitle.isEmpty) {
        warnings.add('parseErrorMsg');
      }

      return ParsedJobLink(
        url: uri,
        site: site,
        companyName: company,
        jobTitle: jobTitle,
        deadlineAt: DateTime.now().add(const Duration(days: 14)),
        deadlineType: DeadlineType.rolling,
        salary: '',
        warnings: warnings,
        isEstimated: true,
      );
    }
  }

  // 1. 공통 JSON-LD 추출 시도
  final jsonLd = _extractFromJsonLd(document);

  // 2. 지역별 파서 선택 및 파싱 시도
  final krParser = KrJobParser(
    parseJobKorea: _parseJobKorea,
    parseSaramin: _parseSaramin,
    parseIncruit: _parseIncruit,
    parseAlbamon: _parseAlbamon,
    parseAlbaheaven: _parseAlbaheaven,
    parseWanted: _parseWanted,
    parseGeneric: _parseGeneric,
    detectSite: _detectSite,
  );

  final globalParser = GlobalJobParser(
    parseLinkedIn: _parseLinkedIn,
    parseIndeed: _parseIndeed,
    parseGlassdoor: _parseGlassdoor,
    parseMonster: _parseMonster,
    parseCareerBuilder: _parseCareerBuilder,
    parseGeneric: _parseGeneric,
    detectSite: _detectSite,
  );

  final jpParser = JpJobParser(
    parseGeneric: _parseGeneric,
    parseIndeedJp: _parseIndeedJp,
    parseRikunabi: _parseRikunabi,
    parseMynavi: _parseMynavi,
    parseWantedly: _parseWantedly,
    parseDoda: _parseDoda,
    parseEnJapan: _parseEnJapan,
    detectSite: _detectSite,
  );

  final cnParser = CnJobParser(
    parseGeneric: _parseGeneric,
    parse51Job: _parse51Job,
    parseZhaopin: _parseZhaopin,
    parseBossZhipin: _parseBossZhipin,
    parseLiepin: _parseLiepin,
    parseLagou: _parseLagou,
    detectSite: _detectSite,
  );

  final inParser = InJobParser(
    parseGeneric: _parseGeneric,
    parseNaukri: _parseNaukri,
    parseIndeedIndia: _parseIndeedIndia,
    parseFoundit: _parseFoundit,
    parseShine: _parseShine,
    parseFreshersworld: _parseFreshersworld,
    detectSite: _detectSite,
  );

  final parserRegion = _detectParserRegion(uri);
  BaseJobParser parser;
  if (site == JobSite.linkedin ||
      site == JobSite.indeed ||
      site == JobSite.glassdoor ||
      site == JobSite.monster ||
      site == JobSite.careerbuilder) {
    parser = globalParser;
  } else if (parserRegion == 'kr') {
    parser = krParser;
  } else if (parserRegion == 'jp') {
    parser = jpParser;
  } else if (parserRegion == 'cn') {
    parser = cnParser;
  } else if (parserRegion == 'in') {
    parser = inParser;
  } else {
    parser = globalParser;
  }

  final siteData = parser.parse(document, title, description, writer, uri);
  bool blockedIndeed = false;

  // 3. 데이터 통합 (JSON-LD 우선, 그 다음 사이트별 데이터)
  var parsedCompany = _cleanCompanyName(_coalesceNonEmpty([jsonLd.companyName, siteData.companyName]));
  var parsedJobTitle = _coalesceNonEmpty([jsonLd.jobTitle, siteData.jobTitle]);
  
  // Indeed의 경우 차단되었거나 데이터를 못 가져온 경우 contextText에서 추출 시도
  if (site == JobSite.indeed && contextText.isNotEmpty) {
    final isBlocked = _isIndeedBlockedDocument(title: title, description: description, bodyText: document.body?.text ?? '');
    blockedIndeed = isBlocked;
    if (isBlocked || parsedCompany.isEmpty || parsedJobTitle.isEmpty) {
      final fallback = _extractTitleCompanyFromContextText(contextText);
      if (parsedCompany.isEmpty && fallback.companyName.isNotEmpty) {
        parsedCompany = _cleanCompanyName(fallback.companyName);
      }
      if (parsedJobTitle.isEmpty && fallback.jobTitle.isNotEmpty) {
        parsedJobTitle = fallback.jobTitle;
      }
    }
  }
  
  // 최종 방어: Indeed 차단 페이지 잔재 제거
  if (site == JobSite.indeed) {
    final jtLower = parsedJobTitle.toLowerCase();
    final coLower = parsedCompany.toLowerCase();
    if (jtLower.contains('just a moment') || jtLower.contains('attention required') || jtLower == 'title') {
      parsedJobTitle = '';
    }
    if (coLower == 'title' || coLower.contains('indeed')) {
      parsedCompany = '';
    }
  }
  
  // 마감일 결정 로직: 
  // 사이트별 파싱에서 '상시채용'으로 판단했다면 JSON-LD의 날짜(주로 placeholder)보다 우선함
  DateTime? date;
  DeadlineType deadlineType;
  bool isEstimated;

  if (siteData.deadlineType == DeadlineType.rolling) {
    date = siteData.deadlineAt;
    deadlineType = DeadlineType.rolling;
    isEstimated = siteData.isEstimated;
  } else {
    date = jsonLd.deadlineAt ?? siteData.deadlineAt;
    deadlineType = jsonLd.deadlineAt != null ? DeadlineType.fixedDate : siteData.deadlineType;
    isEstimated = jsonLd.deadlineAt == null && siteData.isEstimated;
  }

  // LinkedIn 보정: 게시일(datePosted) + 14일을 기준으로 마감일 임시설정
  if (site == JobSite.linkedin) {
    final postedAt = jsonLd.datePosted ?? siteData.datePosted;
    final now = DateTime.now();
    
    // 1. 마감일이 명확하지 않거나 (null), 
    // 2. LinkedIn 특유의 14일 placeholder인 경우 (10~20일 사이),
    // 3. 또는 상시채용(isEstimated)이지만 게시일 정보가 있는 경우 보정 시도
    bool needsCorrection = date == null;
    if (date != null) {
      final diff = date.difference(now).inDays;
      if (diff >= 10 && diff <= 20) {
        needsCorrection = true;
      }
      // 이미 임시설정된 날짜가 현재(오늘)보다 너무 가깝거나(14일 등) 과거인 경우에도 보정
      if (isEstimated && diff < 10) {
        needsCorrection = true;
      }
    }

    if (needsCorrection) {
      DateTime estimated;
      if (postedAt != null) {
        // 게시일 + 14일로 설정
        estimated = postedAt.add(const Duration(days: 14));
        // 만약 게시일+14일이 이미 지났다면(과거라면), 현재 날짜 + 14일로 설정
        if (estimated.isBefore(now)) {
          estimated = now.add(const Duration(days: 14));
        }
      } else {
        // 게시일 정보가 없으면 오늘 + 14일로 설정
        estimated = now.add(const Duration(days: 14));
      }
      
      date = DateTime(estimated.year, estimated.month, estimated.day, 23, 59);
      deadlineType = DeadlineType.rolling;
      isEstimated = true;
    }
  }

  // 급여 결정 로직: 한국어 키워드(내규, 협의, 결정 등)가 포함된 데이터를 우선함
  String salary = '';
  final s1 = siteData.salary;
  final s2 = jsonLd.salary;
  
  final meaningfulKeywords = ['내규', '협의', '원', '만원', '결정', '후'];
  bool isMeaningful(String s) => meaningfulKeywords.any((k) => s.contains(k));

  if (isMeaningful(s1)) {
    salary = s1;
  } else if (isMeaningful(s2)) {
    salary = s2;
  } else {
    salary = _coalesceNonEmpty([s1, s2]);
  }

  final warnings = <String>[];
  if (date == null && deadlineType != DeadlineType.rolling) {
    warnings.add('parseWarningDeadline');
  }
  if (parsedCompany.isEmpty) {
    warnings.add('parseWarningCompany');
  }
  if (parsedJobTitle.isEmpty) {
    warnings.add('parseWarningTitle');
  }
  if (blockedIndeed) {
    warnings.add('parseErrorMsg');
  }

  return ParsedJobLink(
    url: uri,
    site: site,
    companyName: parsedCompany,
    jobTitle: _cleanJobTitle(parsedJobTitle),
    deadlineAt: date,
    deadlineType: deadlineType,
    salary: salary,
    warnings: warnings,
    isEstimated: isEstimated,
  );
}

({String companyName, String jobTitle}) _extractTitleCompanyFromContextText(String contextText) {
  if (contextText.isEmpty) return (companyName: '', jobTitle: '');

  // 1. 전처리: 불필요한 문구 및 URL 제거
  var cleaned = contextText
      .replaceAll(RegExp(r'Indeed에서 이 채용 공고를 확인해 보세요\.?', caseSensitive: false), '')
      .replaceAll(RegExp(r'indeed에서 이 채용 공고를 확인해 보세요\.?', caseSensitive: false), '')
      .replaceAll(RegExp(r'Check out this job at\s+', caseSensitive: false), '')
      .trim();

  final lines = cleaned
      .split(RegExp(r'[\r\n]+'))
      .map((line) => line.replaceAll(RegExp(r'https?://\S+'), '').trim())
      .where((line) => line.isNotEmpty)
      .toList(growable: false);
  
  if (lines.isEmpty) return (companyName: '', jobTitle: '');

  // 2. Indeed 앱 공유 기본 형식 (Company: Job Title)
  final colonPattern = RegExp(r'^(.*?)\s*:\s*(.*)$');
  final mColon = colonPattern.firstMatch(lines.first);
  if (mColon != null) {
    final company = mColon.group(1)?.trim() ?? '';
    final jobTitle = mColon.group(2)?.trim() ?? '';
    if (company.isNotEmpty && jobTitle.isNotEmpty && !company.toLowerCase().contains('http')) {
      return (companyName: company, jobTitle: jobTitle);
    }
  }

  // 3. 다중 라인 형식 (Line 1: Job Title, Line 2: Company)
  final locationKeywords = ['서울', '경기', '인천', '부산', '대구', '광주', '대전', '울산', '세종', '강원', '충북', '충남', '전북', '전남', '경북', '경남', '제주', '수원', '성남', '고양', '용인', '부천', '안산', '안양', '남양주', '화성', '송도', '판교', '청주', '천안', '전주', '창원', '포항', '구미', '진주', '목포', '순천', '익산', '여수', '동대문', '서대문', '강남', '강서', '강북', '강동', '영등포', '구로', '금천', '관악', '동작', '서초', '송파', '마포', '용산', '성동', '광진', '중랑', '노원', '도봉', '은평', '양천', '종로', '중구', '성북'];
  final jobKeywords = ['채용', '모집', '공고', '엔지니어', '개발자', '디자이너', '기획자', '마케터', '영업', '회계', '인사', '총무', '상담원', '배달', '운전', '생산', '제조', '연구원', '기술자', '강사', '요리사', '조리사', '바리스타', '홀서빙', '주방', '알바', '아르바이트', '파트타임', '정규직', '계약직', '파견직', '병역특례'];

  if (lines.length >= 2) {
    final line1 = lines[0];
    final line2 = lines[1];
    
    bool isLine1Job = jobKeywords.any((k) => line1.contains(k));
    bool isLine2Location = locationKeywords.any((k) => line2.contains(k)) && line2.length < 10;
    
    if (isLine1Job && !isLine2Location && !line2.toLowerCase().contains('indeed')) {
       return (companyName: line2, jobTitle: line1);
    } else if (lines.length >= 3) {
      final line3 = lines[2];
      if (isLine1Job && isLine2Location && !line3.toLowerCase().contains('indeed')) {
        return (companyName: line3, jobTitle: line1);
      }
    }
  }

  // 4. 구분자( - , | , / ) 기반 형식
  final firstLine = lines.first;
  final pieces = firstLine
      .split(RegExp(r'\s*[-|/]\s*'))
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList(growable: false);

  if (pieces.length >= 2) {
    final p1 = pieces[0];
    final p2 = pieces[1];
    
    final isP2Location = locationKeywords.any((k) => p2.contains(k)) && p2.length < 6;
    final isP1Job = jobKeywords.any((k) => p1.contains(k));
    final isP2Job = jobKeywords.any((k) => p2.contains(k));

    if (isP1Job && !isP2Location && !p2.toLowerCase().contains('indeed')) {
      return (companyName: p2, jobTitle: p1);
    } else if (isP2Job && !p1.toLowerCase().contains('indeed')) {
      return (companyName: p1, jobTitle: p2);
    } else if (pieces.length >= 3) {
       final third = pieces[2];
       if (!third.toLowerCase().contains('indeed')) {
         return (companyName: third, jobTitle: p1);
       }
    }
  }

  // 5. "회사명 직무" 패턴 (예: "삼성전자 반도체 설계 엔지니어 모집")
  final jobPattern = RegExp(r'([\p{L}\p{N}().·㈜（유）(주)\s]+?)\s*(직원|채용|모집|공고|담당|기사|관리|운영|사원|인턴|전문가|엔지니어|매니저|개발자|디자이너|기획자|마케터|영업|회계|인사|총무|상담원|배달|운전|생산|제조|연구원|기술자|강사|요리사|조리사|바리스타|홀서빙|주방|알바|아르바이트|파트타임|정규직|계약직|파견직|병역특례)', caseSensitive: false, unicode: true);
  final mJob = jobPattern.firstMatch(lines.first);
  if (mJob != null) {
    final company = (mJob.group(1) ?? '').trim();
    if (company.isNotEmpty && company.length > 1) {
      return (companyName: company, jobTitle: lines.first);
    }
  }

  return (companyName: '', jobTitle: lines.first);
}

bool _isIndeedBlockedDocument({required String title, required String description, required String bodyText}) {
    final titleLower = title.toLowerCase();
    final descLower = description.toLowerCase();
    final bodyLower = bodyText.toLowerCase();
    return titleLower.contains('just a moment') ||
        titleLower.contains('잠시만요') ||
        titleLower.contains('attention required') ||
        titleLower.contains('주의가 필요합니다') ||
        titleLower.contains('access denied') ||
        titleLower.contains('blocked') ||
        titleLower == 'title' ||
        descLower.contains('just a moment') ||
        descLower.contains('잠시만요') ||
        bodyLower.contains('verify you are human') ||
        bodyLower.contains('인간 여부 확인') ||
        bodyLower.contains('checking your browser') ||
        bodyLower.contains('브라우저 확인') ||
        bodyLower.contains('bot verification') ||
        bodyLower.contains('봇') ||
        bodyLower.contains('cloudflare') ||
        bodyLower.contains('hcaptcha') ||
        bodyLower.contains('turnstile') ||
        (bodyLower.contains('javascript') && bodyLower.contains('cookie') && bodyLower.length < 1000);
}

String _cleanJobTitle(String title) {
  if (title.isEmpty) return title;

  return title
      // D-Day 패턴 제거: (D-1), D-1, (D-Day), D-Day, (D-상시), D-상시 등
      .replaceAll(RegExp(r'\(?\s*D-(?:Day|\d+|상시)\s*\)?', caseSensitive: false), '')
      // 마감일 패턴 제거: (~02/04), (~ 02/04), (~2026.02.04) 등
      .replaceAll(RegExp(r'\(?\s*~\s*\d{1,2}[./]\d{1,2}\s*\)?'), '')
      .replaceAll(RegExp(r'\(?\s*~\s*\d{4}[./]\d{1,2}[./]\d{1,2}\s*\)?'), '')
      // 불필요한 공백 정리
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

_PartialJobData _parseJobKorea(dom.Document doc, String title, String desc, String writer) {
  // 잡코리아 특화 추출
  final coName = doc.querySelector('.coName')?.text.trim() ?? 
                 doc.querySelector('.company-name')?.text.trim() ?? '';
  final giTitle = doc.querySelector('.giTitle')?.text.trim() ?? 
                  doc.querySelector('.job-title')?.text.trim() ?? '';

  // 잡코리아 모바일/데스크탑 급여 정보 우선 추출
  String? jkSalary;
  final jkSelectors = [
    '.salary',
    '.salary_info',
    '.salary-info',
    '.info_item .salary',
    '.item_info .salary',
  ];
  
  for (final s in jkSelectors) {
    final el = _querySelectorSafe(doc, s);
    if (el != null) {
      final text = _cleanSalaryText(el.text.trim());
      if (text.isNotEmpty && (text.contains('내규') || text.contains('원') || text.contains('협의') || text.contains('결정'))) {
        jkSalary = text;
        break;
      }
    }
  }
  jkSalary ??= _extractSalaryFromLabelSections(doc);

  final bodyText = doc.body?.text ?? '';
  final isRolling = _isRollingDeadline(description: desc, bodyText: bodyText);
  
  // 상시채용이면 날짜 추출을 건너뛰거나, 매우 엄격하게(마감일 키워드 동반)만 추출
  DateTime? date;
  if (isRolling) {
    // 상시채용인 경우 '마감일: 202X.XX.XX' 처럼 아주 명확한 경우만 날짜로 인정
    date = _extractDeadlineSpecific(description: desc, bodyText: bodyText);
  } else {
    date = _extractDeadlineFromAny(description: desc, bodyText: bodyText);
  }
  
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling && date == null) {
      estimatedDate = DateTime.now().add(const Duration(days: 14));
      estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
      isEstimated = true;
    }

  return (
    companyName: coName.isNotEmpty ? coName : _guessCompanyFromTitle(title),
    jobTitle: giTitle.isNotEmpty ? giTitle : _guessJobTitleFromAny(site: JobSite.jobkorea, title: title),
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: jkSalary ?? _extractSalaryFromAny(description: desc, bodyText: bodyText, document: doc),
    isEstimated: isEstimated,
    datePosted: null,
  );
}

_PartialJobData _parseSaramin(dom.Document doc, String title, String desc, String writer) {
  // 사람인 특화 추출
  final coName = doc.querySelector('.company_name')?.text.trim() ?? '';
  final jobTitle = doc.querySelector('.job_title')?.text.trim() ?? '';

  final bodyText = doc.body?.text ?? '';
  final isRolling = _isRollingDeadline(description: desc, bodyText: bodyText);
  
  DateTime? date;
  if (isRolling) {
    date = _extractDeadlineSpecific(description: desc, bodyText: bodyText);
  } else {
    date = _extractDeadlineFromAny(description: desc, bodyText: bodyText);
  }
  
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling && date == null) {
    estimatedDate = DateTime.now().add(const Duration(days: 14));
    estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
    isEstimated = true;
  }

  return (
    companyName: coName.isNotEmpty ? coName : _guessCompanyFromTitle(title),
    jobTitle: jobTitle.isNotEmpty ? jobTitle : _guessJobTitleFromAny(site: JobSite.saramin, title: title),
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: _extractSalaryFromAny(description: desc, bodyText: bodyText, document: doc),
    isEstimated: isEstimated,
    datePosted: null,
  );
}

_PartialJobData _parseLinkedIn(dom.Document doc, String title, String desc, String writer, Uri uri) {
  final pathSegments = uri.pathSegments.map((s) => s.toLowerCase()).toList();
  final isCompanyPage = pathSegments.contains('company') || pathSegments.contains('school');
  
  // LinkedIn 회사 페이지인 경우 (예: https://www.linkedin.com/company/vestas/)
  if (isCompanyPage) {
    final cleanTitle = title.replaceAll(RegExp(r'\s*\|\s*LinkedIn.*$', caseSensitive: false), '').trim();
    
    // 만약 타이틀이 "LinkedIn" 이거나 비어있으면 URL에서 회사명 추출 시도
    String companyName = cleanTitle;
    if (companyName.toLowerCase() == 'linkedin' || companyName.isEmpty) {
      final companyIdx = pathSegments.indexOf('company');
      final schoolIdx = pathSegments.indexOf('school');
      final idx = companyIdx != -1 ? companyIdx : schoolIdx;
      if (idx != -1 && idx + 1 < pathSegments.length) {
        companyName = pathSegments[idx + 1].split('-').map((word) {
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + word.substring(1);
        }).join(' ');
      }
    }

    return (
      companyName: companyName,
      jobTitle: '', // 회사 페이지이므로 구체적인 직무 제목은 없음
      deadlineAt: null,
      deadlineType: DeadlineType.unknown,
      salary: '',
      isEstimated: false,
      datePosted: null,
    );
  }

  final date = _extractDeadlineFromAny(description: desc, bodyText: doc.body?.text ?? '');
  
  // LinkedIn 특유의 상시채용 감지 로직
  final isRolling = date == null && _isRollingDeadline(description: desc, bodyText: doc.body?.text ?? '');
  
  // 게시일 추출 시도 (DOM에서 상대 날짜 등)
  DateTime? datePosted;
  final bodyText = doc.body?.text ?? '';
  final relativeDateMatch = RegExp(r'(\d+)\s*(시간|일|주|달|개월)\s*전').firstMatch(bodyText);
  if (relativeDateMatch != null) {
    final value = int.tryParse(relativeDateMatch.group(1) ?? '');
    final unit = relativeDateMatch.group(2);
    if (value != null) {
      final now = DateTime.now();
      if (unit == '시간') {
        datePosted = now.subtract(Duration(hours: value));
      } else if (unit == '일') {
        datePosted = now.subtract(Duration(days: value));
      } else if (unit == '주') {
        datePosted = now.subtract(Duration(days: value * 7));
      } else if (unit == '달' || unit == '개월') {
        datePosted = now.subtract(Duration(days: value * 30));
      }
    }
  }

  // 상시채용인 경우 14일 뒤로 예상 마감일 설정 (이후 통합 로직에서 게시일 기반으로 보정될 수 있음)
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling) {
    estimatedDate = DateTime.now().add(const Duration(days: 14));
    estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
    isEstimated = true;
  }

  return (
    companyName: _guessCompanyFromLinkedInTitle(title),
    jobTitle: _guessJobTitleFromLinkedInTitle(title),
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: _extractSalaryFromAny(description: desc, bodyText: doc.body?.text ?? '', document: doc),
    isEstimated: isEstimated,
    datePosted: datePosted,
  );
}

_PartialJobData _parseIncruit(dom.Document doc, String title, String desc, String writer) {
  // 인크루트 특화 추출
  String coName = doc.querySelector('.company_name')?.text.trim() ?? 
                 doc.querySelector('.co_name')?.text.trim() ?? 
                 doc.querySelector('.company-name')?.text.trim() ?? 
                 doc.querySelector('.name')?.text.trim() ?? '';
  
  coName = _cleanCompanyName(coName);
  
  // 문서에서 못 찾으면 writer(공유 텍스트)에서 시도
  if (coName.isEmpty && writer.isNotEmpty && !_looksLikeSiteName(site: JobSite.incruit, writer: writer)) {
    coName = _cleanCompanyName(writer);
  }
  
  final jobTitle = doc.querySelector('.job_title')?.text.trim() ?? 
                   doc.querySelector('.job-title')?.text.trim() ?? 
                   doc.querySelector('.tit_job')?.text.trim() ?? '';

  final bodyText = doc.body?.text ?? '';
  final isRolling = _isRollingDeadline(description: desc, bodyText: bodyText);
  
  DateTime? date;
  if (isRolling) {
    date = _extractDeadlineSpecific(description: desc, bodyText: bodyText);
  } else {
    date = _extractDeadlineFromAny(description: desc, bodyText: bodyText);
  }
  
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling && date == null) {
    estimatedDate = DateTime.now().add(const Duration(days: 14));
    estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
    isEstimated = true;
  }

  return (
    companyName: coName.isNotEmpty ? coName : _guessCompanyFromTitle(title),
    jobTitle: jobTitle.isNotEmpty ? jobTitle : _guessJobTitleFromAny(site: JobSite.incruit, title: title),
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: _extractSalaryFromAny(description: desc, bodyText: bodyText, document: doc),
    isEstimated: isEstimated,
    datePosted: null,
  );
}

_PartialJobData _parseAlbamon(dom.Document doc, String title, String desc, String writer) {
  // 알바몬 특화 추출
  String coName = '';
  
  // 회사명 정제 함수 (태그 제거 등)
  String cleanCoName(String name) {
    if (name.isEmpty) return '';
    // '#'이 포함된 단어들을 모두 제거
    final words = name.split(RegExp(r'\s+'));
    final filtered = words.where((word) => !word.contains('#')).join(' ').trim();
    
    // 만약 정제 후에도 '#'이 남아있거나(예: 단어 중간에 #), 
    // 정제 후의 결과가 원래 텍스트와 너무 다르면(태그만 있었던 경우) 비어있는 것으로 간주
    if (filtered.contains('#') || (name.contains('#') && filtered.isEmpty)) {
      return '';
    }
    return filtered;
  }

  // 1. "기업정보" 섹션에서 실제 사업자명 찾기 (가장 정확함)
  final companyInfoSelectors = [
    '.company_info .name',
    '.companyInfo .name',
    '.co_info .name',
    '.company_name',
    '.coName'
  ];
  for (final s in companyInfoSelectors) {
    final el = doc.querySelector(s);
    if (el != null && el.text.trim().isNotEmpty) {
      coName = cleanCoName(el.text.trim());
      if (coName.isNotEmpty && !coName.contains('#')) break;
    }
  }

  // 2. 브랜드명 찾기 (예: "브랜드 쿠팡헬퍼")
  if (coName.isEmpty) {
    final brandSelectors = ['.brand_name', '.brand', '.brandName', '#brandName'];
    for (final s in brandSelectors) {
      final el = doc.querySelector(s);
      if (el != null && el.text.trim().isNotEmpty) {
        String val = el.text.trim();
        // "브랜드" 텍스트가 포함되어 있으면 제거
        val = val.replaceFirst('브랜드', '').trim();
        coName = cleanCoName(val);
        if (coName.isNotEmpty) break;
      }
    }
  }

  // 3. "기업정보" 또는 "브랜드" 텍스트 기반 추출
  if (coName.isEmpty) {
    final labels = doc.querySelectorAll('dt, th, span').where((el) {
      final t = el.text.trim();
      return t.contains('기업정보') || t.contains('브랜드');
    });
    for (final label in labels) {
      final value = label.nextElementSibling?.text.trim() ?? label.parent?.text.replaceFirst(label.text, '').trim() ?? '';
      final cleaned = cleanCoName(value);
      if (cleaned.isNotEmpty && !cleaned.contains('기업정보') && !cleaned.contains('브랜드')) {
        coName = cleaned;
        break;
      }
    }
  }

  // 대행사/파견업체 여부 확인 키워드
  bool isAgency(String name) {
    final agencyKeywords = ['파트너스', '인력', 'HR', '스탭', '서치', '아웃소싱', '맨파워', '컨설팅', '서비코', '코리아파트너스'];
    return agencyKeywords.any((k) => name.contains(k));
  }

  // 만약 coName이 대행사명이거나 여전히 태그가 섞여있다면 제목에서 추론
  if (coName.isEmpty || isAgency(coName) || coName.contains('#')) {
    final guessed = _guessCompanyFromTitle(title);
    if (guessed.isNotEmpty && !isAgency(guessed)) {
      coName = guessed;
    }
  }

  // 4. 작성자 정보 활용 (마지막 수단 중 하나)
  if (coName.isEmpty && writer.isNotEmpty && !_looksLikeSiteName(site: JobSite.albamon, writer: writer)) {
    coName = cleanCoName(writer);
  }

  // 최종 검증: 만약 여전히 '#'이 포함되어 있다면 제목에서 추론하도록 강제
  if (coName.contains('#') || coName.isEmpty) {
    coName = _guessCompanyFromTitle(title);
  }

  final giTitle = doc.querySelector('.giTitle')?.text.trim() ?? '';

  final bodyText = doc.body?.text ?? '';
  final isRolling = _isRollingDeadline(description: desc, bodyText: bodyText);
  
  DateTime? date;
  if (isRolling) {
    date = _extractDeadlineSpecific(description: desc, bodyText: bodyText);
  } else {
    date = _extractDeadlineFromAny(description: desc, bodyText: bodyText);
  }
  
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling && date == null) {
    estimatedDate = DateTime.now().add(const Duration(days: 14));
    estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
    isEstimated = true;
  }

  return (
    companyName: coName.isNotEmpty && !coName.startsWith('#') ? coName : _guessCompanyFromTitle(title),
    jobTitle: giTitle.isNotEmpty ? giTitle : _guessJobTitleFromAny(site: JobSite.albamon, title: title),
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: _extractSalaryFromAny(description: desc, bodyText: bodyText, document: doc),
    isEstimated: isEstimated,
    datePosted: null,
  );
}

_PartialJobData _parseAlbaheaven(dom.Document doc, String title, String desc, String writer) {
  // 알바천국 특화 추출
  final coName = doc.querySelector('.companyName')?.text.trim() ?? 
                 doc.querySelector('.view_header .company')?.text.trim() ?? '';
  final giTitle = doc.querySelector('.jobTitle')?.text.trim() ?? 
                  doc.querySelector('.view_header .title')?.text.trim() ?? '';

  final bodyText = doc.body?.text ?? '';
  final isRolling = _isRollingDeadline(description: desc, bodyText: bodyText);
  
  DateTime? date;
  if (isRolling) {
    date = _extractDeadlineSpecific(description: desc, bodyText: bodyText);
  } else {
    date = _extractDeadlineFromAny(description: desc, bodyText: bodyText);
  }
  
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling && date == null) {
    estimatedDate = DateTime.now().add(const Duration(days: 14));
    estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
    isEstimated = true;
  }

  return (
    companyName: coName.isNotEmpty ? coName : _guessCompanyFromTitle(title),
    jobTitle: giTitle.isNotEmpty ? giTitle : _guessJobTitleFromAny(site: JobSite.albaheaven, title: title),
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: _extractSalaryFromAny(description: desc, bodyText: bodyText, document: doc),
    isEstimated: isEstimated,
    datePosted: null,
  );
}

_PartialJobData _parseWanted(dom.Document doc, String title, String desc, String writer) {
  // 원티드 특화 추출
  // 원티드는 주로 JSON-LD가 잘 되어있지만 보조적으로 체크
  final coName = doc.querySelector('h6[class*="CompanyInfo_name"]')?.text.trim() ?? '';
  final giTitle = doc.querySelector('h2[class*="JobHeader_title"]')?.text.trim() ?? '';

  final bodyText = doc.body?.text ?? '';
  final isRolling = _isRollingDeadline(description: desc, bodyText: bodyText);
  
  DateTime? date;
  if (isRolling) {
    date = _extractDeadlineSpecific(description: desc, bodyText: bodyText);
  } else {
    date = _extractDeadlineFromAny(description: desc, bodyText: bodyText);
  }
  
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling && date == null) {
    estimatedDate = DateTime.now().add(const Duration(days: 14));
    estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
    isEstimated = true;
  }

  return (
    companyName: coName.isNotEmpty ? coName : _guessCompanyFromTitle(title),
    jobTitle: giTitle.isNotEmpty ? giTitle : _guessJobTitleFromAny(site: JobSite.wanted, title: title),
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: _extractSalaryFromAny(description: desc, bodyText: bodyText, document: doc),
    isEstimated: isEstimated,
    datePosted: null,
  );
}

_PartialJobData _parseGeneric(dom.Document doc, String title, String desc, String writer, JobSite site) {
  final writerTrimmed = writer.trim();
  String company = '';
  
  if (writerTrimmed.isNotEmpty && !_looksLikeSiteName(site: site, writer: writerTrimmed)) {
    company = _cleanCompanyName(writerTrimmed);
  } else {
    company = _guessCompanyFromTitle(title);
  }

  final bodyText = doc.body?.text ?? '';
  final isRolling = _isRollingDeadline(description: desc, bodyText: bodyText);
  
  DateTime? date;
  if (isRolling) {
    date = _extractDeadlineSpecific(description: desc, bodyText: bodyText);
  } else {
    date = _extractDeadlineFromAny(description: desc, bodyText: bodyText);
  }
  
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling && date == null) {
    estimatedDate = DateTime.now().add(const Duration(days: 14));
    estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
    isEstimated = true;
  }

  return (
    companyName: company,
    jobTitle: _guessJobTitleFromAny(site: site, title: title),
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: _extractSalaryFromAny(description: desc, bodyText: bodyText, document: doc),
    isEstimated: isEstimated,
    datePosted: null,
  );
}

_PartialJobData _parseIndeedJp(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: [
      '[data-testid="company-name"]',
      '[data-company-name]',
      '[data-testid="inlineHeader-companyName"]',
      '[data-testid="jobsearch-JobInfoHeader-companyName"]',
      '.jobsearch-CompanyInfoWithoutHeaderImage div',
    ],
    titleSelectors: [
      '[data-testid="job-title"]',
      'h1[data-testid="jobsearch-JobInfoHeader-title"]',
      'h1',
    ],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*Indeed.*$', caseSensitive: false),
      RegExp(r'\s*\|\s*Indeed.*$', caseSensitive: false),
    ],
  );
}

_PartialJobData _parseRikunabi(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: [
      '.rnn-jobOfferHeader__companyName',
      '.rnn-companyName',
      '.companyName',
      '[class*="companyName"]',
      '[class*="company"]',
    ],
    titleSelectors: [
      '.rnn-jobOfferHeader__title',
      '.rnn-offerTitle',
      'h1',
      '[class*="jobTitle"]',
    ],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*リクナビ.*$'),
      RegExp(r'\s*\|\s*リクナビ.*$'),
    ],
  );
}

_PartialJobData _parseMynavi(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: ['.companyName', '[class*="companyName"]', '[class*="corpName"]'],
    titleSelectors: ['.jobName', 'h1', '[class*="jobTitle"]'],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*マイナビ.*$'),
      RegExp(r'\s*\|\s*マイナビ.*$'),
    ],
  );
}

_PartialJobData _parseWantedly(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: [
      '[data-testid="company-link"]',
      'a[href*="/companies/"]',
      '[class*="CompanyName"]',
    ],
    titleSelectors: ['h1', '[class*="JobPostTitle"]', '[class*="ProjectTitle"]'],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*Wantedly.*$', caseSensitive: false),
      RegExp(r'\s*\|\s*Wantedly.*$', caseSensitive: false),
    ],
  );
}

_PartialJobData _parseDoda(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: ['.company_name', '.companyName', '[class*="companyName"]'],
    titleSelectors: ['.job_title', 'h1', '[class*="jobTitle"]'],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*doda.*$', caseSensitive: false),
      RegExp(r'\s*\|\s*doda.*$', caseSensitive: false),
    ],
  );
}

_PartialJobData _parseEnJapan(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: ['.companyName', '[class*="company"]'],
    titleSelectors: ['.jobTitle', 'h1', '[class*="job"]'],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*エン転職.*$'),
      RegExp(r'\s*-\s*en-japan.*$', caseSensitive: false),
      RegExp(r'\s*\|\s*en-japan.*$', caseSensitive: false),
    ],
  );
}

_PartialJobData _parse51Job(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: [
      '.com_msg a',
      '.com_tag p a',
      '.job_msg .cn strong',
      '.company_name',
      '.cn p a',
      '[class*="company"]',
    ],
    titleSelectors: [
      '.jobname h1',
      '.cn h1',
      '.jobname',
      'h1',
      '[class*="job-title"]',
    ],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*前程无忧.*$'),
      RegExp(r'\s*-\s*51job.*$', caseSensitive: false),
      RegExp(r'\s*\|\s*51job.*$', caseSensitive: false),
    ],
  );
}

_PartialJobData _parseZhaopin(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: [
      '.company-href__name',
      '.company__name',
      '.company-name',
      '[class*="companyName"]',
      '[class*="company-href"]',
    ],
    titleSelectors: [
      '.job-name__title',
      '.job-name',
      'h1',
      '[class*="jobName"]',
    ],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*智联招聘.*$'),
      RegExp(r'\s*\|\s*智联招聘.*$'),
    ],
  );
}

_PartialJobData _parseBossZhipin(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: ['.company-name', '.brand-name', '[class*="company"]'],
    titleSelectors: ['.name', 'h1', '[class*="job-name"]'],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*BOSS直聘.*$'),
      RegExp(r'\s*\|\s*BOSS直聘.*$'),
    ],
  );
}

_PartialJobData _parseLiepin(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: ['.company-name', '.new-compintro a', '[class*="company"]'],
    titleSelectors: ['.title-info h1', 'h1', '[class*="job-title"]'],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*猎聘.*$'),
      RegExp(r'\s*\|\s*猎聘.*$'),
    ],
  );
}

_PartialJobData _parseLagou(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: ['.employer-name', '.company', '[class*="company"]'],
    titleSelectors: ['.position-head-wrap h1', 'h1', '[class*="position"]'],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*拉勾.*$'),
      RegExp(r'\s*\|\s*拉勾.*$'),
    ],
  );
}

_PartialJobData _parseNaukri(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: [
      '[class*="styles_jd-header-comp-name"] a',
      '[class*="jd-header-comp-name"] a',
      '.jd-header-comp-name',
      '.comp-name',
      'a.comp-name',
      '[class*="company"]',
    ],
    titleSelectors: [
      '[class*="styles_jd-header-title"]',
      '[class*="jd-header-title"]',
      '.jd-header-title',
      'h1',
      '[class*="job-title"]',
    ],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*Naukri.*$', caseSensitive: false),
      RegExp(r'\s*\|\s*Naukri.*$', caseSensitive: false),
    ],
  );
}

_PartialJobData _parseIndeedIndia(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: [
      '[data-testid="company-name"]',
      '[data-company-name]',
      '[data-testid="inlineHeader-companyName"]',
      '[data-testid="jobsearch-JobInfoHeader-companyName"]',
      '.jobsearch-CompanyInfoWithoutHeaderImage div',
    ],
    titleSelectors: [
      '[data-testid="job-title"]',
      'h1[data-testid="jobsearch-JobInfoHeader-title"]',
      'h1',
    ],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*Indeed.*$', caseSensitive: false),
      RegExp(r'\s*\|\s*Indeed.*$', caseSensitive: false),
    ],
  );
}

_PartialJobData _parseFoundit(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: ['.company-name', '[class*="company"]'],
    titleSelectors: ['.job-title', 'h1', '[class*="jobTitle"]'],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*foundit.*$', caseSensitive: false),
      RegExp(r'\s*-\s*Monster.*$', caseSensitive: false),
      RegExp(r'\s*\|\s*foundit.*$', caseSensitive: false),
    ],
  );
}

_PartialJobData _parseShine(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: ['.jobCompanyName', '.recruiter-name', '[class*="company"]'],
    titleSelectors: ['.jobTitle', 'h1', '[class*="job-title"]'],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*Shine.*$', caseSensitive: false),
      RegExp(r'\s*\|\s*Shine.*$', caseSensitive: false),
    ],
  );
}

_PartialJobData _parseFreshersworld(dom.Document doc, String title, String desc, String writer) {
  return _parseRegionalSite(
    doc,
    title,
    desc,
    writer,
    companySelectors: ['.company-name', '[class*="company"]'],
    titleSelectors: ['.job-title', 'h1', '[class*="job-title"]'],
    titleCleanupPatterns: [
      RegExp(r'\s*-\s*Freshersworld.*$', caseSensitive: false),
      RegExp(r'\s*\|\s*Freshersworld.*$', caseSensitive: false),
    ],
  );
}

_PartialJobData _parseRegionalSite(
  dom.Document doc,
  String title,
  String desc,
  String writer, {
  required List<String> companySelectors,
  required List<String> titleSelectors,
  required List<RegExp> titleCleanupPatterns,
}) {
  final base = _parseGeneric(doc, title, desc, writer, JobSite.unknown);
  final extractedCompany = _extractFirstTextBySelectors(doc, companySelectors);
  final extractedJobTitle = _extractFirstTextBySelectors(doc, titleSelectors);
  final cleanedTitle = _cleanupRegionalText(
    extractedJobTitle.isNotEmpty ? extractedJobTitle : title,
    titleCleanupPatterns,
  );
  final finalCompany = extractedCompany.isNotEmpty ? _cleanCompanyName(extractedCompany) : base.companyName;
  final finalTitle = cleanedTitle.isNotEmpty ? cleanedTitle : base.jobTitle;

  return (
    companyName: finalCompany,
    jobTitle: finalTitle,
    deadlineAt: base.deadlineAt,
    deadlineType: base.deadlineType,
    salary: base.salary,
    isEstimated: base.isEstimated,
    datePosted: base.datePosted,
  );
}

String _extractFirstTextBySelectors(dom.Document doc, List<String> selectors) {
  for (final selector in selectors) {
    final text = _querySelectorSafe(doc, selector)?.text.trim() ?? '';
    if (text.isNotEmpty) {
      return text.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
  }
  return '';
}

dom.Element? _querySelectorSafe(dom.Document doc, String selector) {
  try {
    return doc.querySelector(selector);
  } catch (_) {
    return null;
  }
}

_PartialJobData _parseIndeed(dom.Document doc, String title, String desc, String writer, Uri uri) {
    // Indeed 특화 추출 로직
    final bodyText = doc.body?.text ?? '';
    
    // 봇 차단 페이지 여부 확인 ("Just a moment...", "Cloudflare" 등)
    final isBlocked = _isIndeedBlockedDocument(title: title, description: desc, bodyText: bodyText);

    // Indeed에서 회사명 추출 시도
    String companyName = '';
  
  // 1. Indeed 특정 셀렉터로 회사명 추출 (모바일/데스크탑 통합)
  final companySelectors = [
    '.jobsearch-InlineCompanyRating',
    '[data-testid="company-name"]',
    '[data-testid="inlineHeader-companyName"]',
    '[data-testid="jobsearch-JobInfoHeader-companyName"]',
    '.jobsearch-JobInfoHeader-companyName',
    '.companyName',
    '.icl-u-lg-mr--sm',
    '[data-company-name]',
    '.jobsearch-CompanyInfoWithoutHeaderImage div',
  ];
  
  for (final selector in companySelectors) {
    final element = doc.querySelector(selector);
    if (element != null) {
      companyName = element.text.trim();
      if (companyName.isNotEmpty) break;
    }
  }
  
  // 2. 제목에서 회사명 추출 시도 (Indeed 형식: "Job Title - Company Name - Location")
  if (companyName.isEmpty && !isBlocked) {
    final titlePattern = RegExp(r'^(.+?)\s*-\s*(.+?)\s*-\s*(.+?)\s*\|?\s*Indeed\.com.*', caseSensitive: false);
    final match = titlePattern.firstMatch(title);
    if (match != null && match.groupCount >= 2) {
      companyName = match.group(2)?.trim() ?? '';
    }
  }
  
  // 3. JSON-LD 데이터에서 회사명 추출
  if (companyName.isEmpty && !isBlocked) {
    final jsonLd = _extractFromJsonLd(doc);
    companyName = jsonLd.companyName;
  }
  
  // 직무 제목 추출
  String jobTitle = '';
  final jobTitleSelectors = [
    '.jobsearch-JobInfoHeader-title',
    '[data-testid="jobsearch-JobInfoHeader-title"]',
    'h1'
  ];
  
  for (final selector in jobTitleSelectors) {
    final element = doc.querySelector(selector);
    if (element != null) {
      jobTitle = element.text.trim();
      // Indeed 제목에서 " - Indeed" 부분 제거
      jobTitle = jobTitle.replaceAll(RegExp(r'\s*-\s*Indeed\.com.*', caseSensitive: false), '').trim();
      if (jobTitle.isNotEmpty) break;
    }
  }

  // 마감일 추출
  final date = _extractDeadlineFromAny(description: desc, bodyText: bodyText);
  final isRolling = _isRollingDeadline(description: desc, bodyText: bodyText);
  
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling && date == null) {
    estimatedDate = DateTime.now().add(const Duration(days: 14));
    estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
    isEstimated = true;
  }
  
  // 급여 정보 추출
  final salary = _extractSalaryFromAny(description: desc, bodyText: bodyText, document: doc);
  final finalSalary = isBlocked ? '' : salary;
  final finalCompany = isBlocked
      ? ''
      : _cleanCompanyName(companyName.isNotEmpty ? companyName : _guessCompanyFromTitle(title));
  final finalJobTitle = isBlocked
      ? ''
      : (jobTitle.isNotEmpty ? jobTitle : _guessJobTitleFromAny(site: JobSite.indeed, title: title));

  // [수정] 차단 페이지의 잔재가 데이터로 들어오지 않도록 최종 방어
  var cleanedJobTitle = finalJobTitle;
  if (cleanedJobTitle.toLowerCase().contains('just a moment') ||
      cleanedJobTitle.toLowerCase().contains('attention required') ||
      cleanedJobTitle.toLowerCase() == 'title') {
    cleanedJobTitle = '';
  }

  var cleanedCompany = finalCompany;
  if (cleanedCompany.toLowerCase() == 'title' || cleanedCompany.toLowerCase().contains('indeed')) {
    cleanedCompany = '';
  }

  return (
    companyName: cleanedCompany,
    jobTitle: cleanedJobTitle,
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: finalSalary,
    isEstimated: isEstimated,
    datePosted: null,
  );
}

_PartialJobData _parseGlassdoor(dom.Document doc, String title, String desc, String writer, Uri uri) {
  // Glassdoor 특화 추출 로직
  final bodyText = doc.body?.text ?? '';
  
  // Glassdoor에서 회사명 추출 시도
  String companyName = '';
  
  // 1. Glassdoor 특정 셀렉터로 회사명 추출
  final companySelectors = [
    '.employerName',
    '[data-test="employer-name"]',
    '.companyInfo',
    '.employer',
    '[data-company]'
  ];
  
  for (final selector in companySelectors) {
    final element = doc.querySelector(selector);
    if (element != null) {
      companyName = element.text.trim();
      if (companyName.isNotEmpty) break;
    }
  }
  
  // 2. 제목에서 회사명 추출 시도 (Glassdoor 형식: "Job Title - Company Name - Location")
  if (companyName.isEmpty) {
    final titlePattern = RegExp(r'^(.+?)\s*-\s*(.+?)\s*-\s*(.+?)\s*\|?\s*Glassdoor.*', caseSensitive: false);
    final match = titlePattern.firstMatch(title);
    if (match != null && match.groupCount >= 2) {
      companyName = match.group(2)?.trim() ?? '';
    }
  }
  
  // 3. JSON-LD 데이터에서 회사명 추출
  if (companyName.isEmpty) {
    final jsonLd = _extractFromJsonLd(doc);
    companyName = jsonLd.companyName;
  }
  
  // 직무 제목 추출
  String jobTitle = '';
  final jobTitleSelectors = [
    '.jobTitle',
    '[data-test="job-title"]',
    'h1',
    '.job_header'
  ];
  
  for (final selector in jobTitleSelectors) {
    final element = doc.querySelector(selector);
    if (element != null) {
      jobTitle = element.text.trim();
      // Glassdoor 제목에서 " - Glassdoor" 부분 제거
      jobTitle = jobTitle.replaceAll(RegExp(r'\s*-\s*Glassdoor.*', caseSensitive: false), '').trim();
      if (jobTitle.isNotEmpty) break;
    }
  }
  
  // 마감일 추출
  final date = _extractDeadlineFromAny(description: desc, bodyText: bodyText);
  final isRolling = _isRollingDeadline(description: desc, bodyText: bodyText);
  
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling && date == null) {
    estimatedDate = DateTime.now().add(const Duration(days: 14));
    estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
    isEstimated = true;
  }
  
  // 급여 정보 추출
  final salary = _extractSalaryFromAny(description: desc, bodyText: bodyText, document: doc);
  
  return (
    companyName: companyName.isNotEmpty ? companyName : _guessCompanyFromTitle(title),
    jobTitle: jobTitle.isNotEmpty ? jobTitle : _guessJobTitleFromAny(site: JobSite.glassdoor, title: title),
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: salary,
    isEstimated: isEstimated,
    datePosted: null,
  );
}

_PartialJobData _parseMonster(dom.Document doc, String title, String desc, String writer, Uri uri) {
  // Monster 특화 추출 로직
  final bodyText = doc.body?.text ?? '';
  
  // Monster에서 회사명 추출 시도
  String companyName = '';
  
  // 1. Monster 특정 셀렉터로 회사명 추출
  final companySelectors = [
    '.company',
    '.employer-name',
    '[data-testid="company-name"]',
    '.job-company',
    '.job-header-company'
  ];
  
  for (final selector in companySelectors) {
    final element = doc.querySelector(selector);
    if (element != null) {
      companyName = element.text.trim();
      if (companyName.isNotEmpty) break;
    }
  }
  
  // 2. 제목에서 회사명 추출 시도 (Monster 형식: "Job Title at Company Name - Location")
  if (companyName.isEmpty) {
    final titlePattern = RegExp(r'^(.+?)\s+at\s+(.+?)\s*-\s*(.+?)\s*\|?\s*Monster.*', caseSensitive: false);
    final match = titlePattern.firstMatch(title);
    if (match != null && match.groupCount >= 2) {
      companyName = match.group(2)?.trim() ?? '';
    }
  }
  
  // 3. JSON-LD 데이터에서 회사명 추출
  if (companyName.isEmpty) {
    final jsonLd = _extractFromJsonLd(doc);
    companyName = jsonLd.companyName;
  }
  
  // 직무 제목 추출
  String jobTitle = '';
  final jobTitleSelectors = [
    '.job-title',
    '.job-header-title',
    'h1',
    '[data-testid="job-title"]',
    '.job-details-title'
  ];
  
  for (final selector in jobTitleSelectors) {
    final element = doc.querySelector(selector);
    if (element != null) {
      jobTitle = element.text.trim();
      // Monster 제목에서 " - Monster" 부분 제거
      jobTitle = jobTitle.replaceAll(RegExp(r'\s*-\s*Monster.*', caseSensitive: false), '').trim();
      if (jobTitle.isNotEmpty) break;
    }
  }
  
  // 마감일 추출
  final date = _extractDeadlineFromAny(description: desc, bodyText: bodyText);
  final isRolling = _isRollingDeadline(description: desc, bodyText: bodyText);
  
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling && date == null) {
    estimatedDate = DateTime.now().add(const Duration(days: 14));
    estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
    isEstimated = true;
  }
  
  // 급여 정보 추출
  final salary = _extractSalaryFromAny(description: desc, bodyText: bodyText, document: doc);
  
  return (
    companyName: companyName.isNotEmpty ? companyName : _guessCompanyFromTitle(title),
    jobTitle: jobTitle.isNotEmpty ? jobTitle : _guessJobTitleFromAny(site: JobSite.monster, title: title),
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: salary,
    isEstimated: isEstimated,
    datePosted: null,
  );
}

_PartialJobData _parseCareerBuilder(dom.Document doc, String title, String desc, String writer, Uri uri) {
  // CareerBuilder 특화 추출 로직
  final bodyText = doc.body?.text ?? '';
  
  // CareerBuilder에서 회사명 추출 시도
  String companyName = '';
  
  // 1. CareerBuilder 특정 셀렉터로 회사명 추출
  final companySelectors = [
    '.company-name',
    '.employer-name',
    '[data-company-name]',
    '.job-company',
    '.job-details-company'
  ];
  
  for (final selector in companySelectors) {
    final element = doc.querySelector(selector);
    if (element != null) {
      companyName = element.text.trim();
      if (companyName.isNotEmpty) break;
    }
  }
  
  // 2. 제목에서 회사명 추출 시도 (CareerBuilder 형식: "Job Title at Company Name - Location")
  if (companyName.isEmpty) {
    final titlePattern = RegExp(r'^(.+?)\s+at\s+(.+?)\s*-\s*(.+?)\s*\|?\s*CareerBuilder.*', caseSensitive: false);
    final match = titlePattern.firstMatch(title);
    if (match != null && match.groupCount >= 2) {
      companyName = match.group(2)?.trim() ?? '';
    }
  }
  
  // 3. JSON-LD 데이터에서 회사명 추출
  if (companyName.isEmpty) {
    final jsonLd = _extractFromJsonLd(doc);
    companyName = jsonLd.companyName;
  }
  
  // 직무 제목 추출
  String jobTitle = '';
  final jobTitleSelectors = [
    '.job-title',
    '.job-header-title',
    'h1',
    '[data-job-title]',
    '.job-details-title'
  ];
  
  for (final selector in jobTitleSelectors) {
    final element = doc.querySelector(selector);
    if (element != null) {
      jobTitle = element.text.trim();
      // CareerBuilder 제목에서 " - CareerBuilder" 부분 제거
      jobTitle = jobTitle.replaceAll(RegExp(r'\s*-\s*CareerBuilder.*', caseSensitive: false), '').trim();
      if (jobTitle.isNotEmpty) break;
    }
  }
  
  // 마감일 추출
  final date = _extractDeadlineFromAny(description: desc, bodyText: bodyText);
  final isRolling = _isRollingDeadline(description: desc, bodyText: bodyText);
  
  DateTime? estimatedDate;
  bool isEstimated = false;
  if (isRolling && date == null) {
    estimatedDate = DateTime.now().add(const Duration(days: 14));
    estimatedDate = DateTime(estimatedDate.year, estimatedDate.month, estimatedDate.day, 23, 59);
    isEstimated = true;
  }
  
  // 급여 정보 추출
  final salary = _extractSalaryFromAny(description: desc, bodyText: bodyText, document: doc);
  
  return (
    companyName: companyName.isNotEmpty ? companyName : _guessCompanyFromTitle(title),
    jobTitle: jobTitle.isNotEmpty ? jobTitle : _guessJobTitleFromAny(site: JobSite.careerbuilder, title: title),
    deadlineAt: date ?? estimatedDate,
    deadlineType: date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown),
    salary: salary,
    isEstimated: isEstimated,
    datePosted: null,
  );
}

String? _extractSalaryFromLabelSections(dom.Document doc) {
  final labels = <String>{'급여', '연봉', '희망급여'};

  for (final row in doc.querySelectorAll('dl')) {
    final dt = row.querySelector('dt');
    final dd = row.querySelector('dd');
    if (dt == null || dd == null) continue;
    final label = dt.text.replaceAll(RegExp(r'\s+'), '').trim();
    if (!labels.contains(label)) continue;
    final cleaned = _cleanSalaryText(dd.text.trim());
    if (cleaned.isNotEmpty) return cleaned;
  }

  for (final row in doc.querySelectorAll('tr')) {
    final th = row.querySelector('th');
    final td = row.querySelector('td');
    if (th == null || td == null) continue;
    final label = th.text.replaceAll(RegExp(r'\s+'), '').trim();
    if (!labels.contains(label)) continue;
    final cleaned = _cleanSalaryText(td.text.trim());
    if (cleaned.isNotEmpty) return cleaned;
  }

  final linePattern = RegExp(r'(급여|연봉|희망급여)\s*[:：]?\s*(.+)');
  for (final el in doc.querySelectorAll('li, p, div, span')) {
    final text = el.text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty || text.length > 120) continue;
    final match = linePattern.firstMatch(text);
    if (match == null) continue;
    final cleaned = _cleanSalaryText((match.group(2) ?? '').trim());
    if (cleaned.isNotEmpty) return cleaned;
  }

  return null;
}

String _cleanupRegionalText(String value, List<RegExp> patterns) {
  var cleaned = value.replaceAll(RegExp(r'\s+'), ' ').trim();
  for (final pattern in patterns) {
    cleaned = cleaned.replaceAll(pattern, '').trim();
  }
  return cleaned;
}

String _detectParserRegion(Uri uri) {
  final host = uri.host.toLowerCase();

  if (host.contains('jobkorea.co.kr') ||
      host.contains('saram.in') ||
      host.contains('saramin.co.kr') ||
      host.contains('incruit.com') ||
      host.contains('albamon.com') ||
      host.contains('alba.co.kr') ||
      host.contains('wanted.co.kr') ||
      host.endsWith('.kr') ||
      host.contains('.co.kr')) {
    return 'kr';
  }

  if (host.contains('jp.indeed.com') ||
      host.contains('indeed.co.jp') ||
      host.contains('rikunabi.com') ||
      host.contains('mynavi.jp') ||
      host.contains('wantedly.com') ||
      host.contains('doda.jp') ||
      host.contains('en-japan.com') ||
      host.endsWith('.jp') ||
      host.contains('.co.jp')) {
    return 'jp';
  }

  if (host.contains('51job.com') ||
      host.contains('zhaopin.com') ||
      host.contains('zhipin.com') ||
      host.contains('liepin.com') ||
      host.contains('lagou.com') ||
      host.endsWith('.cn') ||
      host.contains('.com.cn')) {
    return 'cn';
  }

  if (host.contains('naukri.com') ||
      host.contains('in.indeed.com') ||
      host.contains('indeed.co.in') ||
      host.contains('foundit.in') ||
      host.contains('monsterindia.com') ||
      host.contains('shine.com') ||
      host.contains('freshersworld.com') ||
      host.endsWith('.in') ||
      host.contains('.co.in')) {
    return 'in';
  }

  return 'global';
}

// Extracted static helpers
Uri? _normalizeUrl(String raw) {
  final trimmed = raw.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();

  if (uri.scheme == 'http' && (host == 'joburl.kr' || host.endsWith('.joburl.kr'))) {
    return uri.replace(scheme: 'https');
  }

  if (host.contains('jobkorea.co.kr') && path.endsWith('/info/app_down.asp')) {
    final gno = uri.queryParameters['Gno'] ?? uri.queryParameters['gno'];
    if (gno != null && RegExp(r'^\d+$').hasMatch(gno)) {
      return Uri.parse('https://www.jobkorea.co.kr/Recruit/GI_Read/$gno');
    }
  }

  return uri;
}

JobSite _detectSite({required Uri uri, required String ogSiteName, required String title}) {
  final host = uri.host.toLowerCase();
  final siteName = ogSiteName.toLowerCase();
  final titleLower = title.toLowerCase();

  if (host.contains('jobkorea.co.kr') || siteName.contains('잡코리아') || titleLower.contains('잡코리아')) {
    return JobSite.jobkorea;
  }
  if (host.contains('saram.in') || host.contains('saramin.co.kr') || siteName.contains('사람인') || titleLower.contains('사람인')) {
    return JobSite.saramin;
  }
  if (host.contains('incruit.com') || siteName.contains('인쿠르트') || titleLower.contains('incruit')) {
    return JobSite.incruit;
  }
  if (host.contains('albamon.com') || siteName.contains('알바몬') || titleLower.contains('알바몬')) {
    return JobSite.albamon;
  }
  if (host.contains('alba.co.kr') || siteName.contains('알바천국') || titleLower.contains('알바천국')) {
    return JobSite.albaheaven;
  }
  if (host.contains('wanted.co.kr') || siteName.contains('원티드') || titleLower.contains('wanted')) {
    return JobSite.wanted;
  }
  if (host.contains('linkedin.com') || host.contains('lnkd.in') || siteName.contains('linkedin') || titleLower.contains('linkedin')) {
    return JobSite.linkedin;
  }
  if (host.contains('indeed.com') || host.contains('indeed.co.kr') || siteName.contains('indeed') || titleLower.contains('indeed')) {
    return JobSite.indeed;
  }
  if (host.contains('glassdoor.com') || siteName.contains('glassdoor') || titleLower.contains('glassdoor')) {
    return JobSite.glassdoor;
  }
  if (host.contains('monster.com') || siteName.contains('monster') || titleLower.contains('monster')) {
    return JobSite.monster;
  }
  if (host.contains('careerbuilder.com') || siteName.contains('careerbuilder') || titleLower.contains('careerbuilder')) {
    return JobSite.careerbuilder;
  }
  return JobSite.unknown;
}

// 기업명 정제 전용 헬퍼 함수
String _cleanCompanyName(String name) {
  if (name.isEmpty) return '';
  
  final lower = name.toLowerCase();
  if (lower == 'indeed' || lower == 'indeed.com' || lower.contains('just a moment')) {
    return '';
  }
  
  // 1. (주), 주식회사 등 법인 형태 제거
  String cleaned = name
      .replaceAll(RegExp(r'\(주\)|주식회사|\(재\)|재단법인|\(유\)|유한회사|\(사\)|사단법인|\(학\)|학교법인|\(의\)|의료법인'), '')
      .trim();
  
  // 2. 콤마, 파이프, 괄호, 슬래시 등을 기준으로 분리하여 첫 번째 부분만 취함
  // 예: "BNK경남은행,BNK" -> "BNK경남은행", "삼성전자 (Samsung)" -> "삼성전자"
  final parts = cleaned.split(RegExp(r'[,|(\[／/｜]')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
  if (parts.isNotEmpty) {
    cleaned = parts[0];
  }
  
  // 3. 중복 공백 제거 및 최종 정제
  return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _guessCompanyFromTitle(String title) {
  final normalized = title.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return '';

  // 0. 봇 차단 페이지 제목 확인
  if (normalized.contains('Just a moment') || 
      normalized.contains('Verify you are human') || 
      normalized.contains('Checking your browser')) {
    return '';
  }

  // 1. 제외할 키워드 (지역, 채용 형태 등)
  final skipKeywords = [
    '정규직', '계약직', '파견직', '아르바이트', '알바', '모집', '채용', '급구', '단기', '장기', 
    '신입', '경력', '무관', '우대', '전체', '상시', '대규모', '전국', '서울', '경기', '인천',
    '년 상반기', '년 하반기', 'NEXT CAREER', '공채', '특채', '상반기', '하반기', '채용공고', // 인크루트 특화 제외 키워드 추가
    'Just a moment', 'Verify you are human', 'Checking your browser' // 봇 차단 문구 추가
  ];

  // 2. 대괄호 추출 시도
  final bracketMatches = RegExp(r'\[(.+?)\]').allMatches(normalized);
  for (final match in bracketMatches) {
    String content = (match.group(1) ?? '').trim();
    content = _cleanCompanyName(content);
    
    // 알바몬 특유의 태그나 지역/형태 정보는 건너뜀
    bool shouldSkip = content.contains('#') || 
                     content.contains('/') || 
                     content.contains('원') || 
                     content.contains('만원') ||
                     skipKeywords.any((k) => content.contains(k));
    
    if (!shouldSkip && content.length > 1 && content.length < 20) {
      return content;
    }
  }

  // 3. 대괄호 이후의 텍스트에서 회사명 찾기 시도
  final afterBracketText = normalized.replaceAll(RegExp(r'\[.+?\]'), ' ').trim();
  if (afterBracketText.isNotEmpty) {
    final parts = afterBracketText.split(RegExp(r'\s+'));
    for (var part in parts) {
      part = _cleanCompanyName(part);

      // 너무 짧거나 제외 키워드면 건너뜀
      if (part.length <= 1 || skipKeywords.any((k) => part.contains(k))) continue;
      
      if (part.length < 20) {
        return part;
      }
      break;
    }
  }

  // 4. "회사명 채용 : 직무" 또는 "회사명 채용 - 직무" 패턴 (인크루트, 사람인 등)
  final jobPattern = RegExp(r'^(.*?)\s*채용\s*[:|-]\s*(.*?)\s*[-|\|]');
  final m = jobPattern.firstMatch(normalized);
  if (m != null) {
    String company = (m.group(1) ?? '').trim();
    company = _cleanCompanyName(company);

    if (company.isNotEmpty && company.length < 20) {
      return company;
    }
  }

  // 5. 기존 "회사명 채용 - 직무 | 사이트" 패턴
  final m2 = RegExp(r'^(.*?)\s*채용\s*-\s*(.*?)\s*\|').firstMatch(normalized);
  if (m2 != null) {
    String company = (m2.group(1) ?? '').trim();
    company = _cleanCompanyName(company);
    if (company.isNotEmpty) return company;
  }
  final comma = normalized.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (comma.length >= 2 && comma.first.length <= 20) {
    return comma.first;
  }
  final separators = <String>['|', '-', '·', '｜', ':', '：'];
  for (final sep in separators) {
    final parts = normalized.split(sep).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      final company = parts.first.replaceAll(RegExp(r'\s*(채용|모집).*$'), '').trim();
      if (company.isNotEmpty) return company;
    }
  }
  return '';
}

String _guessJobTitleFromAny({required JobSite site, required String title}) {
  if (site == JobSite.linkedin) {
    return _guessJobTitleFromLinkedInTitle(title);
  }
  final normalized = title.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return '';
  final bracket = RegExp(r'^\[(.+?)\]\s*(.+)$').firstMatch(normalized);
  if (bracket != null) {
    final rest = (bracket.group(2) ?? '').trim();
    if (rest.isNotEmpty) {
      // 사이트 이름 제거 로직 통합
      final cleaned = rest
          .replaceAll(RegExp(r'\s*-\s*사람인.*$'), '')
          .replaceAll(RegExp(r'\s*\|\s*잡코리아.*$'), '')
          .replaceAll(RegExp(r'\s*채용\s*공고\s*\|\s*원티드.*$'), '')
          .replaceAll(RegExp(r'\s*-\s*인크루트.*$'), '')
          .replaceAll(RegExp(r'\s*\|\s*알바몬.*$'), '')
          .replaceAll(RegExp(r'\s*\|\s*알바천국.*$'), '')
          .trim();
      return cleaned;
    }
  }
  final m = RegExp(r'^(.*?)\s*채용\s*-\s*(.*?)\s*\|').firstMatch(normalized);
  if (m != null) {
    final job = (m.group(2) ?? '').trim();
    if (job.isNotEmpty) {
      return job.replaceAll(RegExp(r'\s*(잡코리아|사람인|원티드|인크루트|알바몬|알바천국).*$'), '').trim();
    }
  }
  final comma = normalized.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (comma.length >= 2) {
    final rest = comma.sublist(1).join(', ').trim();
    if (rest.isNotEmpty) return rest;
  }
  final separators = <String>['|', '-', '·', '｜', ':', '：'];
  for (final sep in separators) {
    final parts = normalized.split(sep).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      // 만약 마지막 파트가 사이트 이름이면 제외하고 그 앞 파트를 제목으로 사용
      String candidate = parts.first;
      if (parts.length >= 3) {
        final last = parts.last;
        if (last.contains('사람인') || last.contains('잡코리아') || last.contains('원티드') || 
            last.contains('인크루트') || last.contains('알바몬') || last.contains('알바천국')) {
          candidate = parts[parts.length - 2];
        }
      }
      return candidate;
    }
  }
  return normalized;
}

DateTime? _extractDeadlineSpecific({required String description, required String bodyText}) {
  final combined = '$description\n${bodyText.replaceAll('\u00a0', ' ')}';
  
  // 마감일 키워드와 함께 등장하는 날짜만 추출
  final patterns = [
    RegExp(r'(?:마감일|Application deadline)\s*[:：]?\s*(\d{4})[.\-/ ](\d{1,2})[.\-/ ](\d{1,2})', caseSensitive: false),
    RegExp(r'(?:마감일|Application deadline)\s*[:：]?\s*(\d{1,2})[.\-/ ](\d{1,2})[.\-/ ](\d{4})', caseSensitive: false),
    RegExp(r'유효기간\s*[:：]\s*(\d{4})[.\-/ ](\d{1,2})[.\-/ ](\d{1,2})'),
    RegExp(r'~?\s*(\d{4})[.\-/ ](\d{1,2})[.\-/ ](\d{1,2})\s*까지'),
    RegExp(r'마감\s*[:：]?\s*(\d{4})[.\-/ ](\d{1,2})[.\-/ ](\d{1,2})'),
  ];

  final combinedLower = combined.toLowerCase();
  for (final p in patterns) {
    final match = p.firstMatch(combined);
    if (match != null) {
      int year, month, day;
      if (match.group(1)!.length == 4) {
        year = int.parse(match.group(1)!);
        month = int.parse(match.group(2)!);
        day = int.parse(match.group(3)!);
      } else {
        day = int.parse(match.group(1)!);
        month = int.parse(match.group(2)!);
        year = int.parse(match.group(3)!);
      }
      try {
        return DateTime(year, month, day, 23, 59);
      } catch (_) {}
    }
  }

  // LinkedIn 등의 공고에서 "Application deadline: 08/02/2026" 같은 텍스트가 
  // 다른 문장과 섞여있을 때를 위한 추가 검색
  final deadlineMatch = RegExp(r'application\s+deadline\s*[:：]?\s*(\d{1,2})[.\-/](\d{1,2})[.\-/](\d{4})', caseSensitive: false).firstMatch(combinedLower);
  if (deadlineMatch != null) {
    final d = int.parse(deadlineMatch.group(1)!);
    final m = int.parse(deadlineMatch.group(2)!);
    final y = int.parse(deadlineMatch.group(3)!);
    try {
      return DateTime(y, m, d, 23, 59);
    } catch (_) {}
  }
  return null;
}

DateTime? _extractDeadlineFromAny({required String description, required String bodyText}) {
  // 1. 우선 명확한 패턴(마감일 키워드 동반)부터 시도
  final specific = _extractDeadlineSpecific(description: description, bodyText: bodyText);
  if (specific != null) return specific;

  final descNormalized = description.replaceAll('\u00a0', ' ');
  // ... (기존 m1, m1b, m2 패턴들은 이미 특정 키워드를 포함하므로 유지해도 좋으나, 
  //     최대한 중복을 피하기 위해 여기서는 생략하거나 통합 관리 가능)
  
  final m2 = RegExp(r'마감일\s*[:：]?\s*~?\s*(\d{2})/(\d{2})').firstMatch(descNormalized);
  if (m2 != null) {
    final month = int.parse(m2.group(1)!);
    final day = int.parse(m2.group(2)!);
    final now = DateTime.now();
    var year = now.year;
    final candidate = DateTime(year, month, day);
    if (candidate.isBefore(DateTime(now.year, now.month, now.day))) {
      year = now.year + 1;
    }
    return DateTime(year, month, day, 23, 59);
  }

  final combined = '$descNormalized\n${bodyText.replaceAll('\u00a0', ' ')}';
  final normalized = combined;
  
  // 2. 아주 일반적인 날짜 패턴은 '마감' 근처에 있을 때만 채택하도록 제한
  final patterns = <RegExp>[
    RegExp(r'(\d{4})[.\-/ ](\d{1,2})[.\-/ ](\d{1,2})'),
    RegExp(r'(\d{1,2})[.\-/ ](\d{1,2})[.\-/ ](\d{4})'),
    RegExp(r'(\d{2})[.\-/ ](\d{1,2})[.\-/ ](\d{1,2})'),
  ];

  for (final pattern in patterns) {
    final matches = pattern.allMatches(normalized);
    for (final match in matches) {
      // 해당 매치 주변에 '마감', '종료', '채용', 'deadline' 등의 키워드가 있는지 확인 (전후 20자)
      final start = (match.start - 20).clamp(0, normalized.length);
      final end = (match.end + 20).clamp(0, normalized.length);
      final context = normalized.substring(start, end).toLowerCase();
      
      if (context.contains('마감') || context.contains('종료') || context.contains('채용') || context.contains('까지') || context.contains('deadline')) {
        int year, month, day;
        if (match.group(1)!.length == 4) {
          year = int.parse(match.group(1)!);
          month = int.parse(match.group(2)!);
          day = int.parse(match.group(3)!);
        } else if (match.group(3)!.length == 4) {
          day = int.parse(match.group(1)!);
          month = int.parse(match.group(2)!);
          year = int.parse(match.group(3)!);
        } else {
          final y = int.parse(match.group(1)!);
          year = 2000 + y;
          month = int.parse(match.group(2)!);
          day = int.parse(match.group(3)!);
        }
        
        // 게시일(datePosted) 등으로 오인될 수 있는 과거 날짜는 제외 (오늘 기준 7일 이전이면 마감일로 부적절)
        try {
          final dt = DateTime(year, month, day, 23, 59);
          if (dt.isAfter(DateTime.now().subtract(const Duration(days: 7)))) {
            return dt;
          }
        } catch (_) {}
      }
    }
  }
  return null;
}

String _extractSalaryFromAny({required String description, required String bodyText, dom.Document? document}) {
  // 1. 구체적인 패턴 매칭 우선 (월급/연봉/시급/Salary + 숫자 범위/금액)
  final combinedText = '$description\n$bodyText'.replaceAll('\u00a0', ' ');
  final patterns = [
    // Korean patterns
    RegExp(r'(월급|연봉|시급|일급)\s*[:：]?\s*([\d,.~~\s]+(만원|원|달러))(\s*\([^)]+\))?'),
    RegExp(r'급여\s*[:：]?\s*([\d,.~~\s]+(만원|원|달러))'),
    RegExp(r'(연봉|월급)\s*([\d,.~~\s]+(만원|원|달러))'),
    
    // English/Global patterns (require at least one digit and specific currency/period)
    RegExp(r'(Salary|Wage|Pay)\s*[:：]?\s*(starting\s+at|up\s+to|around)?\s*([€$£\s]*[\d,.]+[\d][\d,.]*[€$£\s]*(?:p\.a\.|p\.m\.|per\s+year|per\s+month|yearly|monthly))', caseSensitive: false),
    RegExp(r'([\d,.]*[\d][\d,.]*[€$£]\s*(?:p\.a\.|p\.m\.|per\s+year|per\s+month))', caseSensitive: false),
  ];

  for (final p in patterns) {
    final match = p.firstMatch(combinedText);
    if (match != null) {
      String res = _cleanSalaryText(match.group(0)!.trim());
      if (res.isNotEmpty && !res.contains('최저시급')) return res;
    }
  }

  // 2. 한국어 주요 키워드 체크 (내규, 협의 등) - 구체적 금액이 없을 때만
  final keywordPattern = RegExp(r'(회사내규|내규|협의|면접\s*후)\s*(?:에\s*따름|결정|후\s*결정)?');
  final keywordMatch = keywordPattern.firstMatch(combinedText);
  if (keywordMatch != null) {
    final start = (keywordMatch.start - 100).clamp(0, combinedText.length);
    final context = combinedText.substring(start, keywordMatch.end);
    if (context.contains('급여') || 
        context.contains('연봉') || 
        context.contains('월급') || 
        context.contains('시급') ||
        context.contains('경력') ||
        context.contains('학력')) {
      return keywordMatch.group(0)!.trim();
    }
  }

  // 3. 사이트별 특정 셀렉터 시도
  String? selectorText;
  if (document != null) {
    // DL/DT/DD 구조 (모바일 사이트들에서 흔함)
    for (final dl in document.querySelectorAll('dl')) {
      final dt = dl.querySelector('dt');
      final dd = dl.querySelector('dd');
      if (dt != null && dd != null) {
        final dtText = dt.text.trim();
        // '급여제도'는 복리후생 항목이므로 제외, 정확히 '급여'나 '연봉'인 경우만
        if (dtText == '급여' || dtText == '연봉' || dtText == '희망급여') {
          String ddText = dd.text.trim();
          if (ddText.isNotEmpty && ddText != ',') {
            ddText = _cleanSalaryText(ddText);
            return ddText;
          }
        }
      }
    }

    final selectors = [
      '.jv_summary .cont .salary', // Saramin Desktop
      '.item_info .desc',          // Saramin Mobile
      '.item_info .cont',          // Saramin Mobile (Alternative)
      '.salary',                  // Generic/JobKorea/Wanted
      '.info_item .salary',       // JobKorea
      '.salary_range',            // Generic
      '.pay_info .pay',           // Albaheaven
      '.view_header .salary',     // Albamon
      '.description__text',       // LinkedIn
      '.show-more-less-html__markup',
      '.job-description',
      '#job-details'
    ];
    for (final s in selectors) {
      final el = _querySelectorSafe(document, s);
      if (el != null && el.text.trim().isNotEmpty) {
        String text = el.text.trim();
        
        // 알바몬 연봉 텍스트가 여러 줄일 경우 첫 줄(정확한 금액)만 가져오도록 시도
        if (s == '.view_header .salary' && text.contains('\n')) {
          text = text.split('\n').first.trim();
        }

        // Albamon 등에서 발생하는 불필요한 정보 제거
        text = _cleanSalaryText(text);
        if (text.isEmpty) continue;
        
        // 만약 셀렉터에서 가져온 텍스트에 이미 '내규', '원', '만원', '결정' 등이 포함되어 있다면 즉시 반환
        final meaningfulKeywords = ['내규', '협의', '원', '만원', '결정', '후'];
        if (meaningfulKeywords.any((k) => text.contains(k))) {
          return text;
        }
        selectorText = text;
        break;
      }
    }
  }

  final textToSearch = selectorText != null ? '$selectorText\n$combinedText' : combinedText;

  // 4. 추가 구체적 패턴 매칭 (중복 방지를 위해 이미 위에서 처리되지 않은 경우만)
  final secondaryPatterns = [
    // 기존 [^,|...] 패턴은 콤마가 포함된 숫자를 끊어버리므로, 
    // 명확하게 키워드(내규, 협의 등)가 포함된 경우만 가져오거나 
    // 줄바꿈 전까지 가져오도록 보완
    RegExp(r'급여\s*[:：]\s*([^|\n\r\t]{2,30})'),
    
    // English/Global patterns (require at least one digit and specific currency/period)
    RegExp(r'(Salary|Wage|Pay)\s*[:：]?\s*(starting\s+at|up\s+to|around)?\s*([€$£\s]*[\d,.]+[\d][\d,.]*[€$£\s]*(?:p\.a\.|p\.m\.|per\s+year|per\s+month|yearly|monthly))', caseSensitive: false),
    RegExp(r'([\d,.]*[\d][\d,.]*[€$£]\s*(?:p\.a\.|p\.m\.|per\s+year|per\s+month))', caseSensitive: false),
  ];

  for (final p in secondaryPatterns) {
    final match = p.firstMatch(textToSearch);
    if (match != null) {
      String res = match.group(0)!.trim();
      
      // 만약 추출된 텍스트 내부에 "Application"이나 "Deadline"이 포함되어 있다면 그 직전까지만 자름
      final deadlineIdx = res.toLowerCase().indexOf('application');
      final deadlineIdx2 = res.toLowerCase().indexOf('deadline');
      int cutIdx = -1;
      if (deadlineIdx != -1 && deadlineIdx2 != -1) {
        cutIdx = deadlineIdx < deadlineIdx2 ? deadlineIdx : deadlineIdx2;
      } else if (deadlineIdx != -1) {
        cutIdx = deadlineIdx;
      } else if (deadlineIdx2 != -1) {
        cutIdx = deadlineIdx2;
      }
      
      if (cutIdx != -1) {
        res = res.substring(0, cutIdx).trim();
        // 자르고 난 뒤 마침표나 쉼표가 남으면 제거
        res = res.replaceAll(RegExp(r'[.,:：\s]+$'), '');
      }

      // 접두어 제거 및 정규화
      final lowerRes = res.toLowerCase();
      if (lowerRes.startsWith('salary')) {
        res = res.replaceFirst(RegExp(r'^salary\s*[:：]?\s*', caseSensitive: false), '').trim();
      } else if (lowerRes.startsWith('wage')) {
        res = res.replaceFirst(RegExp(r'^wage\s*[:：]?\s*', caseSensitive: false), '').trim();
      } else if (lowerRes.startsWith('pay')) {
        res = res.replaceFirst(RegExp(r'^pay\s*[:：]?\s*', caseSensitive: false), '').trim();
      } else if (res.startsWith('급여')) {
        res = res.replaceFirst(RegExp(r'^급여\s*[:：]\s*'), '').trim();
      }
      
      if (res.startsWith('월급')) {
        final val = res.replaceFirst('월급', '').trim().replaceAll(RegExp(r'^[.,:：\s]+'), '');
        if (val.isEmpty) return '';
        return val.contains('/') ? val : '$val/월';
      }
      if (res.startsWith('연봉')) {
        final val = res.replaceFirst('연봉', '').trim().replaceAll(RegExp(r'^[.,:：\s]+'), '');
        if (val.isEmpty) return '';
        return val.contains('/') ? val : '$val/연';
      }
      if (res.startsWith('시급')) {
        final val = res.replaceFirst('시급', '').trim().replaceAll(RegExp(r'^[.,:：\s]+'), '');
        if (val.isEmpty) return '';
        return val.contains('/') ? val : '$val/시';
      }
      if (res.startsWith('일급')) {
        final val = res.replaceFirst('일급', '').trim().replaceAll(RegExp(r'^[.,:：\s]+'), '');
        if (val.isEmpty) return '';
        return val.contains('/') ? val : '$val/일';
      }
      if (res.startsWith('급여')) {
        final val = res.replaceFirst(RegExp(r'^급여\s*[:：]\s*'), '').trim().replaceAll(RegExp(r'^[.,:：\s]+'), '');
        if (val.isEmpty) return '';
        return val;
      }
      return res;
    }
  }

  // 4. 토큰 기반 검색 (기존 로직 유지하되 영어 키워드 추가)
  final tokens = textToSearch.split(RegExp(r'[,|\n\r\t]')).map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  for (final t in tokens) {
    final lower = t.toLowerCase();
    final excluded = lower.startsWith('경력') ||
        lower.startsWith('학력') ||
        lower.startsWith('experience') ||
        lower.startsWith('education') ||
        lower.startsWith('마감일') ||
        lower.startsWith('deadline') ||
        lower.startsWith('홈페이지') ||
        lower.startsWith('location') ||
        lower.startsWith('지역') ||
        lower.startsWith('근무');
    if (excluded) continue;
    
    // 급여 관련 키워드나 통화 기호가 포함된 토큰 반환
    if (t.contains('만원') || t.contains('원') || t.contains('달러') || t.contains('내규') || t.contains('협의') || t.contains('면접') ||
        t.contains('€') || t.contains('\$') || t.contains('£') ||
        lower.contains('salary') || lower.contains('pay') || lower.contains('wage')) {
      // 추출된 토큰이 의미 없는 기호만 포함하는지 마지막으로 확인
      final cleanedToken = t.replaceAll(RegExp(r'[^\w\s가-힣원만원]'), '').trim();
      if (cleanedToken.isEmpty) continue;
      
      return t;
    }
  }

  return '';
}

({String companyName, String jobTitle, DateTime? deadlineAt, String salary, DateTime? datePosted}) _extractFromJsonLd(
  dynamic document,
) {
  try {
    final scripts = (document.querySelectorAll('script[type="application/ld+json"]') as List);
    for (final s in scripts) {
      final raw = (s.text as String?)?.trim();
      if (raw == null || raw.isEmpty) continue;
      final decoded = jsonDecode(raw);
      final items = decoded is List ? decoded : <dynamic>[decoded];
      for (final item in items) {
        if (item is! Map) continue;
        final type = (item['@type'] as String?) ?? '';
        if (type != 'JobPosting') continue;
        final title = (item['title'] as String?) ?? '';
        final org = item['hiringOrganization'];
        String company = '';
        if (org is Map) {
          company = (org['name'] as String?) ?? '';
        }
        final datePostedStr = (item['datePosted'] as String?) ?? '';
        DateTime? postedAt;
        if (datePostedStr.isNotEmpty) {
          postedAt = DateTime.tryParse(datePostedStr);
        }

        final validThrough = (item['validThrough'] as String?) ?? '';
        DateTime? deadline;
        if (validThrough.isNotEmpty) {
          deadline = DateTime.tryParse(validThrough);
          if (deadline != null) {
            deadline = DateTime(deadline.year, deadline.month, deadline.day, 23, 59);
          }
        }
        final baseSalary = item['baseSalary'];
        String salary = '';
        if (baseSalary is Map) {
          final v = baseSalary['value'];
          final unit = (v is Map ? (v['unitText'] as String?) : null) ?? 
                       (baseSalary['salaryCurrency'] as String?) ?? '';
          
          if (v is Map) {
            final amount = v['value'];
            final min = v['minValue'];
            final max = v['maxValue'];
            
            if (min != null && max != null) {
              final fMin = _formatSalary(min, '');
              final fMax = _formatSalary(max, unit);
              if (fMin.isNotEmpty && fMax.isNotEmpty) {
                salary = '$fMin ~ $fMax';
              } else if (fMin.isNotEmpty) {
                salary = fMin;
              } else if (fMax.isNotEmpty) {
                salary = fMax;
              }
            } else if (amount != null) {
              salary = _formatSalary(amount, unit);
            }
          } else if (v != null) {
            salary = _formatSalary(v, unit);
          }
        }
        return (
          companyName: company.trim(),
          jobTitle: title.trim(),
          deadlineAt: deadline,
          salary: salary.trim(),
          datePosted: postedAt,
        );
      }
    }
  } catch (_) {}
  return (companyName: '', jobTitle: '', deadlineAt: null, salary: '', datePosted: null);
}

String _formatSalary(dynamic value, String unitText) {
  if (value == null) return '';
  
  // 만약 값이 이미 범위 형태(300-350 등)를 포함하고 있다면, 
  // 숫자를 하나로 합치지 말고 그대로 반환 시도
  if (value is String && (value.contains('~') || value.contains('-'))) {
    return '$value${unitText.isEmpty ? '' : ' $unitText'}'.trim();
  }

  num? number;
  if (value is num) {
    number = value;
  } else if (value is String) {
    // 숫자가 아닌 문자를 모두 제거할 때, 범위 기호가 있으면 위에서 처리됨.
    // 여기서는 단순 숫자 포맷팅만 수행.
    final cleaned = value.replaceAll(RegExp(r'[^\d.]'), '');
    if (cleaned.isEmpty) {
      // 숫자가 없는 경우 바로 반환하지 말고 아래의 hasMeaningfulChar 체크를 거치도록 함
      number = null;
    } else {
      number = num.tryParse(cleaned);
    }
  }

  if (number == null) {
    final res = '$value${unitText.isEmpty ? '' : ' $unitText'}'.trim();
    // 숫자가 아닌 경우, 의미 있는 글자가 하나라도 포함되어 있는지 확인 (기호만 있는 경우 제외)
    final hasMeaningfulChar = res.contains(RegExp(r'[a-zA-Z가-힣0-9]'));
    if (!hasMeaningfulChar) return '';
    return res;
  }

  // 100보다 작은 숫자가 달러($)로 들어오는 경우, 한국 공고에서는 오류일 가능성이 높음 (예: 날짜의 '8'을 가져오는 등)
  if (number < 100 && (unitText == '\$' || unitText.toUpperCase() == 'USD')) {
    return ''; // 신뢰할 수 없는 데이터로 판단하여 비움
  }

  final formatter = NumberFormat('#,###');
  final formattedNumber = formatter.format(number);

  String unit = '';
  final upperUnit = unitText.toUpperCase();
  if (upperUnit == 'DAY' || upperUnit == 'DAILY') {
    unit = '원/일';
  } else if (upperUnit == 'MONTH' || upperUnit == 'MONTHLY') {
    unit = '원/월';
  } else if (upperUnit == 'YEAR' || upperUnit == 'YEARLY') {
    unit = '원/연';
  } else if (upperUnit == 'HOUR' || upperUnit == 'HOURLY') {
    unit = '원/시';
  } else if (unitText.isEmpty) {
    // 기본적으로 한국어 환경이므로 '원'을 기본으로 하되, 
    // 숫자가 10000보다 작으면 '만원'일 가능성도 고려 (하지만 여기서는 일단 '원'으로 표시 후 사용자가 수정하게 함)
    unit = '원';
  } else {
    unit = ' $unitText';
  }

  return '$formattedNumber$unit';
}

bool _isRollingDeadline({required String description, required String bodyText}) {
  final rollingKeywords = [
    '상시',
    '채용시 마감',
    '채용 시 마감',
    '채용 시까지',
    '채용시까지',
    '수시채용',
    'Rolling',
    'until filled',
    'open until filled',
    'rolling applications',
    'hiring now',
    'apply now',
    'ongoing',
  ];
  final text = (description + bodyText).toLowerCase();
  
  // LinkedIn 특유의 "지원을 클릭한 사람" 또는 "applicants" 패턴 (동적 로딩 대응)
  final linkedinIndicators = [
    'applicants',
    '지원을 클릭한 사람',
    '지원을 클릭한',
    '명 지원',
    '명+ 지원',
  ];
  
  if (rollingKeywords.any((k) => text.contains(k.toLowerCase()))) return true;
  if (linkedinIndicators.any((k) => text.contains(k.toLowerCase()))) return true;
  
  return false;
}

String _guessCompanyFromLinkedInTitle(String title) {
  final clean = title.replaceAll(RegExp(r'\s*\|\s*LinkedIn.*$', caseSensitive: false), '').trim();
  if (clean.isEmpty) return '';

  // 1. "Company Name hiring Job Title" (New Pattern from Screenshot)
  final hiringMatch = RegExp(r'^(.+?)\s+hiring\s+(.+)$', caseSensitive: false).firstMatch(clean);
  if (hiringMatch != null) {
    return hiringMatch.group(1)!.trim();
  }

  // 2. "Job Title at Company Name" (English)
  final atMatch = RegExp(r'^(.+?)\s+at\s+(.+)$', caseSensitive: false).firstMatch(clean);
  if (atMatch != null) {
    return atMatch.group(2)!.trim();
  }

  // 3. "Job Title | Company Name"
  final pipeParts = clean.split('|').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (pipeParts.length >= 2) {
    return pipeParts.last;
  }
  if (pipeParts.length == 1 && clean.isNotEmpty) {
    return clean;
  }

  // 4. "Company Name Job Title 채용중" (Korean locale SEO title)
  if (clean.endsWith('채용중')) {
    final withoutRecruit = clean.substring(0, clean.length - 3).trim();
    final words = withoutRecruit.split(' ');
    if (words.length >= 2) {
      return words.take(2).join(' ');
    }
    return words.first;
  }

  return '';
}

String _guessJobTitleFromLinkedInTitle(String title) {
  final clean = title.replaceAll(RegExp(r'\s*\|\s*LinkedIn.*$', caseSensitive: false), '').trim();
  if (clean.isEmpty) return '';

  // 1. "Company Name hiring Job Title" (New Pattern)
  final hiringMatch = RegExp(r'^(.+?)\s+hiring\s+(.+)$', caseSensitive: false).firstMatch(clean);
  if (hiringMatch != null) {
    return hiringMatch.group(2)!.trim();
  }

  // 2. "Job Title at Company Name" (English)
  final atMatch = RegExp(r'^(.+?)\s+at\s+(.+)$', caseSensitive: false).firstMatch(clean);
  if (atMatch != null) {
    return atMatch.group(1)!.trim();
  }

  // 3. "Job Title | Company Name"
  final pipeParts = clean.split('|').map((e) => e.trim()).toList();
  if (pipeParts.length >= 2) {
    return pipeParts.first;
  }

  // 4. "Company Name Job Title 채용중" (Korean locale SEO title)
  if (clean.endsWith('채용중')) {
    final withoutRecruit = clean.substring(0, clean.length - 3).trim();
    final words = withoutRecruit.split(' ');
    if (words.length >= 2) {
      return words.skip(2).join(' ').trim();
    }
    return withoutRecruit;
  }

  return clean;
}

bool _looksLikeSiteName({required JobSite site, required String writer}) {
  final w = writer.trim();
  if (w.isEmpty) return false;
  if (w == '사람인' || w == '잡코리아' || w == '인크루트' || w == '알바몬') return true;
  if (site == JobSite.saramin && w.contains('사람인')) return true;
  if (site == JobSite.jobkorea && w.contains('잡코리아')) return true;
  return false;
}

String _coalesceNonEmpty(List<String> values) {
  for (final v in values) {
    final t = v.trim();
    if (t.isNotEmpty) return t;
  }
  return '';
}

String _cleanSalaryText(String text) {
  if (text.isEmpty) return text;

  // 1. 공통 노이즈 제거 (연도별 최저시급 정보 등)
  text = text.replaceAll(RegExp(r'\d{4}년\s*최저시급\s*[\d,.]+원'), '');

  // 2. 알바 사이트 특화 버튼/안내 텍스트 제거
  final noiseKeywords = [
    '합격 시 급여를 미리 선지급 받을 수 있는 제트캐시 이용이 가능합니다',
    '제트캐시 상세보기',
    '상세요강 확인필요',
    '제트캐시 이용가능 공고',
    '합격하면 월급날 전에 알바비를미리 받을 수 있는 공고에요',
    '제트캐시',
    '페이워치',
    '선지급',
    '식대별도지급',
    '급여계산기',
    '급여설정기',
    '시급계산기',
    '수습기간있음',
    '수습기간 협의',
    '주휴수당별도',
    '주휴수당포함',
    '면접비지급',
  ];

  for (final noise in noiseKeywords) {
    text = text.replaceAll(noise, '');
  }

  // 3. 금액(원/만원) 뒤에 붙은 설명 텍스트 과감하게 자르기
  // 예: "월급 2,800,000원합격 시..." -> "월급 2,800,000원"
  final salaryEndPattern = RegExp(r'([\d,.~~\s]+(?:만원|원|달러))');
  final match = salaryEndPattern.firstMatch(text);
  if (match != null) {
    // 금액 패턴이 발견되면 그 직후에 오는 조사나 불필요한 문구 확인
    final endPos = match.end;
    if (endPos < text.length) {
      final remaining = text.substring(endPos).trim();
      // 만약 남은 텍스트가 숫자로 시작하지 않고, '시', '합', '제', '확' 등 노이즈 시작 단어라면 자름
      if (remaining.isNotEmpty && !RegExp(r'^[0-9/~]').hasMatch(remaining)) {
        text = text.substring(0, endPos);
      }
    }
  }

  // 4. 연속된 공백 및 줄바꿈 정리
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  // 5. 불필요한 괄호 및 문장 부호 정리
  text = text.replaceAll(RegExp(r'\(\s*\)'), '');
  text = text.replaceAll(RegExp(r'[.,:：\s]+$'), '');

  // 6. 의미 없는 단일 특수문자나 기호만 남은 경우 빈 문자열 반환
  // 예: "$", ",", ".", " ", " $ " 등
  final hasMeaningfulChar = text.contains(RegExp(r'[a-zA-Z가-힣0-9]'));
  if (!hasMeaningfulChar) return '';

  // 7. 급여 정보로서의 가치 확인 (숫자나 '내규', '협의' 등 주요 키워드가 최소한 하나는 있어야 함)
  // "mdrd" 같은 쓰레기 데이터 필터링
  final isLikelySalary = text.contains(RegExp(r'\d')) || 
                        text.contains('내규') || 
                        text.contains('협의') || 
                        text.contains('결정') ||
                        text.contains('원') ||
                        text.contains('만원') ||
                        text.contains('달러') ||
                        text.contains(RegExp(r'[$€£]'));
  
  if (!isLikelySalary && text.length < 10) return '';

  return text.trim();
}

bool _isIndeedUri(Uri uri) {
  final host = uri.host.toLowerCase();
  return host.contains('indeed.');
}

bool _looksLikeIndeedBlockedPage(String html) {
  if (html.isEmpty) return false;
  final lower = html.toLowerCase();
  
  // 1. 일반적인 차단 문구
  final hasBlockedKeywords = lower.contains('just a moment') ||
      lower.contains('잠시만요') ||
      lower.contains('attention required') ||
      lower.contains('주의가 필요합니다') ||
      lower.contains('verify you are human') ||
      lower.contains('인간 여부 확인') ||
      lower.contains('checking your browser') ||
      lower.contains('브라우저 확인') ||
      lower.contains('cloudflare') ||
      lower.contains('access denied') ||
      lower.contains('blocked') ||
      lower.contains('bot verification') ||
      lower.contains('봇') ||
      lower.contains('hcaptcha') ||
      lower.contains('turnstile');

  // 2. 특이 케이스: 타이틀이 "title"이거나 아주 짧은 HTML
  final isSuspiciousTitle = lower.contains('<title>title</title>');
  final isMinimalHtml = lower.length < 2000 && (lower.contains('javascript') || lower.contains('cookie'));
  
  // 3. Indeed 전용: 실제 공고 내용이 전혀 없는 경우
  final isMissingContent = lower.contains('indeed') && 
                           !lower.contains('jobsearch-JobInfoHeader') && 
                           !lower.contains('vjs-jobtitle');

  return hasBlockedKeywords || isSuspiciousTitle || (isMinimalHtml && isMissingContent);
}

Map<String, String> _requestHeaders() {
  return {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'ko-KR,ko;q=0.9,en-US;q=0.8,en;q=0.7',
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
    'Upgrade-Insecure-Requests': '1',
    'Sec-Fetch-Dest': 'document',
    'Sec-Fetch-Mode': 'navigate',
    'Sec-Fetch-Site': 'none',
    'Sec-Fetch-User': '?1',
    'Priority': 'u=0, i',
    'DNT': '1',
  };
}

Uri? _buildIndeedRetryUri(Uri uri) {
  if (!_isIndeedUri(uri)) return null;

  // jk(Job Key)가 있으면 SPA API 엔드포인트로 전환 시도
  final jk = uri.queryParameters['jk'];
  if (jk != null) {
    final params = Map<String, String>.from(uri.queryParameters);
    params['spa'] = '1';
    // 모바일 경로면 데스크탑 경로로 전환
    final path = uri.path.startsWith('/m/viewjob') ? '/viewjob' : uri.path;
    return uri.replace(path: path, queryParameters: params);
  }

  if (uri.path.startsWith('/m/viewjob')) {
    return uri.replace(path: uri.path.replaceFirst('/m/viewjob', '/viewjob'));
  }
  final host = uri.host.toLowerCase();
  if (host.startsWith('m.')) {
    return uri.replace(host: uri.host.substring(2));
  }
  return null;
}

Future<String> _decodeHtml(http.Response response) async {
  final bytes = response.bodyBytes;
  final contentType = response.headers['content-type'] ?? '';
  final charset = RegExp(r'charset=([^\s;]+)', caseSensitive: false).firstMatch(contentType)?.group(1);
  final ascii = latin1.decode(bytes, allowInvalid: true);
  final metaCharset = RegExp(r'''<meta[^>]*charset=["']?([^"'>\s]+)''', caseSensitive: false)
      .firstMatch(ascii)
      ?.group(1);
  final chosen = (charset ?? metaCharset ?? '').toLowerCase();

  if (chosen.contains('euc-kr') || chosen.contains('euckr')) {
    try {
      return await CharsetConverter.decode('euc-kr', bytes);
    } catch (_) {
      return latin1.decode(bytes, allowInvalid: true);
    }
  }
  if (chosen.contains('utf-8') || chosen.contains('utf8')) {
    return utf8.decode(bytes, allowMalformed: true);
  }
  try {
    return utf8.decode(bytes);
  } catch (_) {
    return latin1.decode(bytes, allowInvalid: true);
  }
}

class JobLinkParser {
  ParsedJobLink testParse(
    dom.Document doc,
    String title,
    String description,
    String writer,
    String ogSiteName,
    Uri uri,
    JobSite site,
  ) {
    return _parseHtmlContent(_ParseInput(doc.outerHtml, uri.toString(), writer));
  }

  Future<ParsedJobLink> parse(String rawUrl, {String? contextText}) async {
    final uri = _normalizeUrl(rawUrl);
    if (uri == null || !uri.hasScheme) {
      return ParsedJobLink(
        url: Uri(),
        site: JobSite.unknown,
        companyName: '',
        jobTitle: '',
        deadlineAt: null,
        deadlineType: DeadlineType.unknown,
        salary: '',
        warnings: <String>['parseErrorMsg'],
        isEstimated: false,
      );
    }

    http.Response? response;
    String html = '';
    var finalUrl = uri.toString();

    try {
      response = await http.get(uri, headers: _requestHeaders());
      html = await _decodeHtml(response);
      finalUrl = response.request?.url.toString() ?? uri.toString();
    } catch (e) {
      // HTTP 요청 자체가 실패한 경우 (네트워크 오류 등)
      if (contextText != null && contextText.trim().isNotEmpty) {
        final fallback = _extractTitleCompanyFromContextText(contextText);
        if (fallback.companyName.isNotEmpty || fallback.jobTitle.isNotEmpty) {
          return ParsedJobLink(
            url: uri,
            site: _detectSite(uri: uri, ogSiteName: '', title: ''),
            companyName: _cleanCompanyName(fallback.companyName),
            jobTitle: fallback.jobTitle,
            deadlineAt: null,
            deadlineType: DeadlineType.unknown,
            salary: '',
            warnings: const <String>['parseErrorMsg'],
            isEstimated: false,
          );
        }
      }
      rethrow; // fallback도 없으면 원래대로 에러 던짐
    }

    final resolvedUri = response.request?.url ?? uri;
    final isBlocked = response.statusCode == 403 || response.statusCode == 429 || _looksLikeIndeedBlockedPage(html);

    if (_isIndeedUri(resolvedUri) && isBlocked) {
    // Indeed 차단 시 contextText fallback 우선 시도
    if (contextText != null && contextText.trim().isNotEmpty) {
      final fallback = _extractTitleCompanyFromContextText(contextText);
      if (fallback.companyName.isNotEmpty && fallback.jobTitle.isNotEmpty) {
        return ParsedJobLink(
          url: resolvedUri,
          site: JobSite.indeed,
          companyName: _cleanCompanyName(fallback.companyName),
          jobTitle: fallback.jobTitle,
          deadlineAt: DateTime.now().add(const Duration(days: 14)),
          deadlineType: DeadlineType.rolling,
          salary: '',
          warnings: const <String>[],
          isEstimated: true,
        );
      }
    }

    final retryUri = _buildIndeedRetryUri(resolvedUri);
    if (retryUri != null) {
      try {
        final retryResponse = await http.get(retryUri, headers: _requestHeaders());
        final retryBody = await _decodeHtml(retryResponse);
        if (retryBody.trim().startsWith('{')) {
          try {
            final data = json.decode(retryBody);
            return _parseIndeedJson(data, retryUri, contextText);
          } catch (_) {}
        }
        if (!_looksLikeIndeedBlockedPage(retryBody) && retryResponse.statusCode == 200) {
          html = retryBody;
          finalUrl = retryResponse.request?.url.toString() ?? retryUri.toString();
        } else {
          // Jina Proxy 시도: 프록시 HTML을 정상 파서로 재파싱
          final proxyUri = Uri.parse('https://r.jina.ai/${resolvedUri.toString()}');
          final proxyResponse = await http.get(proxyUri, headers: _requestHeaders());
          final proxyBody = await _decodeHtml(proxyResponse);
          if (proxyBody.isNotEmpty && !proxyBody.trim().startsWith('{')) {
            try {
              final parsedViaProxy = await compute(_parseHtmlContent, _ParseInput(proxyBody, resolvedUri.toString(), contextText));
              if ((parsedViaProxy.companyName.isNotEmpty) || (parsedViaProxy.jobTitle.isNotEmpty)) {
                return parsedViaProxy;
              }
            } catch (_) {
              // 파서 실패 시 텍스트 기반 fallback 시도
              final fb = _extractTitleCompanyFromContextText(proxyBody);
              if ((fb.companyName.isNotEmpty) || (fb.jobTitle.isNotEmpty)) {
                return ParsedJobLink(
                  url: resolvedUri,
                  site: JobSite.indeed,
                  companyName: _cleanCompanyName(fb.companyName),
                  jobTitle: fb.jobTitle,
                  deadlineAt: null,
                  deadlineType: DeadlineType.unknown,
                  salary: '',
                  warnings: const <String>[],
                  isEstimated: false,
                );
              }
            }
          }
          // 로컬 브라우저 스크레이퍼 서비스 시도 (Playwright/stealth)
          try {
            final serviceUri = Uri.parse('http://localhost:3400/scrape?url=${Uri.encodeComponent(resolvedUri.toString())}');
            final svcResp = await http.get(serviceUri);
            if (svcResp.statusCode == 200) {
              final data = json.decode(svcResp.body);
              final svcCompany = _cleanCompanyName((data['companyName'] ?? '').toString());
              final svcTitle = (data['jobTitle'] ?? '').toString();
              if (svcCompany.isNotEmpty || svcTitle.isNotEmpty) {
                return ParsedJobLink(
                  url: resolvedUri,
                  site: JobSite.indeed,
                  companyName: svcCompany,
                  jobTitle: svcTitle,
                  deadlineAt: DateTime.now().add(const Duration(days: 14)),
                  deadlineType: DeadlineType.rolling,
                  salary: '',
                  warnings: const <String>[],
                  isEstimated: true,
                );
              }
            }
          } catch (_) {}
        }
      } catch (_) {
        // Retry/Proxy 실패 시에도 contextText fallback이 있으므로 계속 진행
      }
    }

    // 모든 시도가 실패하고 차단된 상태라면 contextText fallback 우선 적용
    if (contextText != null && contextText.trim().isNotEmpty) {
      final fallback = _extractTitleCompanyFromContextText(contextText);
      if (fallback.companyName.isNotEmpty || fallback.jobTitle.isNotEmpty) {
        return ParsedJobLink(
          url: resolvedUri,
          site: JobSite.indeed,
          companyName: _cleanCompanyName(fallback.companyName),
          jobTitle: fallback.jobTitle,
          deadlineAt: DateTime.now().add(const Duration(days: 14)),
          deadlineType: DeadlineType.rolling,
          salary: '',
          warnings: const <String>[],
          isEstimated: true,
        );
      }
    }
  }

    return compute(_parseHtmlContent, _ParseInput(html, finalUrl, contextText));
  }

  ParsedJobLink _parseIndeedJson(Map<String, dynamic> data, Uri uri, String? contextText) {
    try {
      // Indeed SPA API 응답 구조는 다양할 수 있음
      Map<String, dynamic>? jobData;
      
      if (data.containsKey('hostQueryExecutionResult')) {
        final res = data['hostQueryExecutionResult'];
        if (res is List && res.isNotEmpty) {
          jobData = res[0]?['data']?['jobData'];
        } else if (res is Map) {
          jobData = res['data']?['jobData'];
        }
      } else if (data['body'] is Map && data['body'].containsKey('hostQueryExecutionResult')) {
        final res = data['body']['hostQueryExecutionResult'];
        if (res is List && res.isNotEmpty) {
          jobData = res[0]?['data']?['jobData'];
        } else if (res is Map) {
          jobData = res['data']?['jobData'];
        }
      } else if (data['data'] != null && data['data']['jobData'] != null) {
        jobData = data['data']['jobData'];
      } else if (data['jobData'] != null) {
        jobData = data['jobData'];
      } else if (data['results'] != null) {
        jobData = {'results': data['results']};
      }
      
      final results = jobData?['results'];
      
      if (results == null || (results as List).isEmpty) {
        // results가 없으면 직접 job 필드가 있는지 확인 (단일 결과인 경우)
        final job = jobData?['job'] ?? data['job'];
        if (job != null) {
          return _parseIndeedJobMap(job, uri, contextText);
        }

        // JSON 파싱 실패 시 contextText fallback 시도
        if (contextText != null && contextText.trim().isNotEmpty) {
          final fallback = _extractTitleCompanyFromContextText(contextText);
          if (fallback.companyName.isNotEmpty || fallback.jobTitle.isNotEmpty) {
            return ParsedJobLink(
              url: uri,
              site: JobSite.indeed,
              companyName: _cleanCompanyName(fallback.companyName),
              jobTitle: fallback.jobTitle,
              deadlineAt: DateTime.now().add(const Duration(days: 14)),
              deadlineType: DeadlineType.rolling,
              salary: '',
              warnings: const [],
              isEstimated: true,
            );
          }
        }
        return _createEmptyParsedJobLink(uri);
      }

      final job = results[0]['job'] ?? results[0];
      return _parseIndeedJobMap(job, uri, contextText);
    } catch (e) {
      return _createEmptyParsedJobLink(uri);
    }
  }

  ParsedJobLink _parseIndeedJobMap(Map<String, dynamic> job, Uri uri, String? contextText) {
    final companyName = _cleanCompanyName(job['sourceEmployerName'] ?? job['company']?['name'] ?? '');
    final jobTitle = job['title'] ?? '';
    final description = job['description']?['text'] ?? job['description'] ?? '';
    
    // 급여 정보
    String salary = '';
    final compensation = job['compensation'];
    if (compensation != null) {
      if (compensation is Map) {
        salary = compensation['label'] ?? compensation['text'] ?? '';
        // structured compensation data가 있는 경우 (min/max/type 등)
        if (salary.isEmpty && (compensation['min'] != null || compensation['max'] != null)) {
          final min = compensation['min']?.toString() ?? '';
          final max = compensation['max']?.toString() ?? '';
          final type = compensation['type'] ?? '';
          if (min.isNotEmpty && max.isNotEmpty) {
            salary = '$min - $max ($type)';
          } else if (min.isNotEmpty) {
            salary = '$min ($type)';
          }
        }
      } else if (compensation is String) {
        salary = compensation;
      }
    }

    // 마감일/타입
    final date = _extractDeadlineFromAny(description: description, bodyText: description);
    final isRolling = _isRollingDeadline(description: description, bodyText: description);

    DateTime? deadlineAt = date;
    DeadlineType deadlineType = date != null ? DeadlineType.fixedDate : (isRolling ? DeadlineType.rolling : DeadlineType.unknown);
    bool isEstimated = false;

    if (deadlineType == DeadlineType.unknown) {
      deadlineAt = DateTime.now().add(const Duration(days: 14));
      deadlineAt = DateTime(deadlineAt.year, deadlineAt.month, deadlineAt.day, 23, 59);
      deadlineType = DeadlineType.rolling;
      isEstimated = true;
    }

    // JSON 데이터가 부실할 경우 contextText fallback 결합
    var finalCompany = companyName;
    var finalJobTitle = jobTitle;
    
    if (contextText != null && contextText.trim().isNotEmpty) {
      final fallback = _extractTitleCompanyFromContextText(contextText);
      if (finalCompany.isEmpty && fallback.companyName.isNotEmpty) {
        finalCompany = _cleanCompanyName(fallback.companyName);
      }
      if (finalJobTitle.isEmpty && fallback.jobTitle.isNotEmpty) {
        finalJobTitle = fallback.jobTitle;
      }
    }

    final warnings = <String>[];
    if (finalCompany.isEmpty) warnings.add('parseWarningCompany');
    if (finalJobTitle.isEmpty) warnings.add('parseWarningTitle');

    return ParsedJobLink(
      url: uri,
      site: JobSite.indeed,
      companyName: finalCompany,
      jobTitle: _cleanJobTitle(finalJobTitle),
      deadlineAt: deadlineAt,
      deadlineType: deadlineType,
      salary: salary,
      warnings: warnings,
      isEstimated: isEstimated,
    );
  }

  ParsedJobLink _createEmptyParsedJobLink(Uri uri) {
    return ParsedJobLink(
      url: uri,
      site: JobSite.indeed,
      companyName: '',
      jobTitle: '',
      deadlineAt: null,
      deadlineType: DeadlineType.unknown,
      salary: '',
      warnings: ['parseErrorMsg'],
      isEstimated: false,
    );
  }

}
