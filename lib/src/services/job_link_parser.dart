import 'dart:convert';

import 'package:charset_converter/charset_converter.dart';
import 'package:flutter/foundation.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/job_site.dart';

class ParsedJobLink {
  ParsedJobLink({
    required this.url,
    required this.site,
    required this.companyName,
    required this.jobTitle,
    required this.deadlineAt,
    required this.salary,
    required this.warnings,
  });

  final Uri url;
  final JobSite site;
  final String companyName;
  final String jobTitle;
  final DateTime? deadlineAt;
  final String salary;
  final List<String> warnings;
}

// Input DTO for compute
class _ParseInput {
  final String html;
  final String url;
  _ParseInput(this.html, this.url);
}

// Top-level function for compute
ParsedJobLink _parseHtmlContent(_ParseInput input) {
  final uri = Uri.parse(input.url);
  final document = html_parser.parse(input.html);

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

  final jsonLd = _extractFromJsonLd(document);

  final parsedCompany = _coalesceNonEmpty(
    <String>[jsonLd.companyName, _guessCompanyFromAny(site: site, title: title, writer: writer)],
  );
  final parsedJobTitle = _coalesceNonEmpty(
    <String>[jsonLd.jobTitle, _guessJobTitleFromAny(site: site, title: title)],
  );

  final date = jsonLd.deadlineAt ??
      _extractDeadlineFromAny(description: description, bodyText: document.body?.text ?? '');
  final salary = _coalesceNonEmpty(
    <String>[jsonLd.salary, _extractSalaryFromAny(description: description, bodyText: document.body?.text ?? '')],
  );

  final warnings = <String>[];
  if (date == null) {
    warnings.add('마감일을 자동으로 찾지 못했어요. 직접 선택해 주세요.');
  }
  if (parsedCompany.isEmpty) {
    warnings.add('회사명을 자동으로 찾지 못했어요.');
  }
  if (parsedJobTitle.isEmpty) {
    warnings.add('공고 제목을 자동으로 찾지 못했어요.');
  }

  return ParsedJobLink(
    url: uri,
    site: site,
    companyName: parsedCompany,
    jobTitle: parsedJobTitle,
    deadlineAt: date,
    salary: salary,
    warnings: warnings,
  );
}

// Extracted static helpers
Uri? _normalizeUrl(String raw) {
  final trimmed = raw.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();

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
  return JobSite.unknown;
}

String _guessCompanyFromAny({required JobSite site, required String title, required String writer}) {
  final writerTrimmed = writer.trim();
  if (writerTrimmed.isNotEmpty && !_looksLikeSiteName(site: site, writer: writerTrimmed)) {
    return writerTrimmed;
  }
  return _guessCompanyFromTitle(title);
}

String _guessCompanyFromTitle(String title) {
  final normalized = title.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return '';
  final bracket = RegExp(r'^\[(.+?)\]\s*(.+)$').firstMatch(normalized);
  if (bracket != null) {
    final company = (bracket.group(1) ?? '').trim();
    if (company.isNotEmpty) return company;
  }
  final m = RegExp(r'^(.*?)\s*채용\s*-\s*(.*?)\s*\|').firstMatch(normalized);
  if (m != null) {
    final company = (m.group(1) ?? '').trim();
    if (company.isNotEmpty) return company;
  }
  final comma = normalized.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (comma.length >= 2 && comma.first.length <= 20) {
    return comma.first;
  }
  final separators = <String>['|', '-', '·', '｜'];
  for (final sep in separators) {
    final parts = normalized.split(sep).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return parts.last;
    }
  }
  return '';
}

String _guessJobTitleFromAny({required JobSite site, required String title}) {
  final normalized = title.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (normalized.isEmpty) return '';
  final bracket = RegExp(r'^\[(.+?)\]\s*(.+)$').firstMatch(normalized);
  if (bracket != null) {
    final rest = (bracket.group(2) ?? '').trim();
    if (rest.isNotEmpty) {
      final cleaned = rest.replaceAll(RegExp(r'\s*-\s*사람인.*$'), '').trim();
      return cleaned;
    }
  }
  final m = RegExp(r'^(.*?)\s*채용\s*-\s*(.*?)\s*\|').firstMatch(normalized);
  if (m != null) {
    final job = (m.group(2) ?? '').trim();
    if (job.isNotEmpty) return job;
  }
  final comma = normalized.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  if (comma.length >= 2) {
    final rest = comma.sublist(1).join(', ').trim();
    if (rest.isNotEmpty) return rest;
  }
  final separators = <String>['|', '-', '·', '｜'];
  for (final sep in separators) {
    final parts = normalized.split(sep).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return parts.first;
    }
  }
  return normalized;
}

DateTime? _extractDeadlineFromAny({required String description, required String bodyText}) {
  final descNormalized = description.replaceAll('\u00a0', ' ');
  final m1 = RegExp(r'마감일\s*[:：]\s*(\d{4})\.(\d{2})\.(\d{2})').firstMatch(descNormalized);
  if (m1 != null) {
    final year = int.parse(m1.group(1)!);
    final month = int.parse(m1.group(2)!);
    final day = int.parse(m1.group(3)!);
    return DateTime(year, month, day, 23, 59);
  }

  final m1b = RegExp(r'마감일\s*[:：]\s*(\d{4})-(\d{2})-(\d{2})').firstMatch(descNormalized);
  if (m1b != null) {
    final year = int.parse(m1b.group(1)!);
    final month = int.parse(m1b.group(2)!);
    final day = int.parse(m1b.group(3)!);
    return DateTime(year, month, day, 23, 59);
  }

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
  final patterns = <RegExp>[
    RegExp(r'(\d{4})[.\-/ ](\d{1,2})[.\-/ ](\d{1,2})'),
    RegExp(r'(\d{2})[.\-/ ](\d{1,2})[.\-/ ](\d{1,2})'),
  ];

  for (final pattern in patterns) {
    final match = pattern.firstMatch(normalized);
    if (match == null) continue;
    final y = int.parse(match.group(1)!);
    final year = y < 100 ? 2000 + y : y;
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    try {
      return DateTime(year, month, day, 23, 59);
    } catch (_) {
      continue;
    }
  }
  return null;
}

String _extractSalaryFromAny({required String description, required String bodyText}) {
  final desc = description.replaceAll('\u00a0', ' ');
  final m1 = RegExp(r'급여\s*[:：]\s*([^,]+)').firstMatch(desc);
  if (m1 != null) {
    return (m1.group(1) ?? '').trim();
  }

  final tokens = desc.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();
  for (final t in tokens) {
    final lower = t.toLowerCase();
    final excluded = lower.startsWith('경력') ||
        lower.startsWith('학력') ||
        lower.startsWith('마감일') ||
        lower.startsWith('홈페이지') ||
        lower.startsWith('지역') ||
        lower.startsWith('근무');
    if (excluded) continue;
    final looksLikeSalary = t.contains('원') || t.contains('내규') || t.contains('협의') || t.contains('면접');
    if (looksLikeSalary) return t;
  }

  final normalized = bodyText.replaceAll('\u00a0', ' ');
  final m2 = RegExp(r'급여\s*[:：]\s*([^\n\r]+)').firstMatch(normalized);
  if (m2 != null) {
    return (m2.group(1) ?? '').trim();
  }
  return '';
}

({String companyName, String jobTitle, DateTime? deadlineAt, String salary}) _extractFromJsonLd(
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
          if (v is Map) {
            final amount = v['value'];
            final unit = (v['unitText'] as String?) ?? '';
            if (amount != null) {
              salary = _formatSalary(amount, unit);
            }
          }
        }
        return (companyName: company.trim(), jobTitle: title.trim(), deadlineAt: deadline, salary: salary.trim());
      }
    }
  } catch (_) {}
  return (companyName: '', jobTitle: '', deadlineAt: null, salary: '');
}

String _formatSalary(dynamic value, String unitText) {
  num? number;
  if (value is num) {
    number = value;
  } else if (value is String) {
    number = num.tryParse(value.replaceAll(RegExp(r'[^\d.]'), ''));
  }

  if (number == null) {
    return '$value${unitText.isEmpty ? '' : ' $unitText'}'.trim();
  }

  final formatter = NumberFormat('#,###');
  final formattedNumber = formatter.format(number);

  String unit = '';
  switch (unitText.toUpperCase()) {
    case 'DAY':
      unit = '원/일';
      break;
    case 'MONTH':
      unit = '원/월';
      break;
    case 'YEAR':
      unit = '원/연';
      break;
    case 'HOUR':
      unit = '원/시';
      break;
    default:
      unit = unitText.isEmpty ? '원' : ' $unitText';
  }

  return '$formattedNumber$unit';
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

class JobLinkParser {
  Future<ParsedJobLink> parse(String rawUrl) async {
    final uri = _normalizeUrl(rawUrl);
    if (uri == null || !uri.hasScheme) {
      return ParsedJobLink(
        url: Uri(),
        site: JobSite.unknown,
        companyName: '',
        jobTitle: '',
        deadlineAt: null,
        salary: '',
        warnings: <String>['유효한 URL이 아닙니다.'],
      );
    }

    final response = await http.get(
      uri,
      headers: const {'User-Agent': 'Mozilla/5.0'},
    );

    final html = await _decodeHtml(response);
    
    // Use compute to parse HTML in a background isolate
    return compute(_parseHtmlContent, _ParseInput(html, uri.toString()));
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
}
