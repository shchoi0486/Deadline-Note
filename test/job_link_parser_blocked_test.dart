import 'package:flutter_test/flutter_test.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:deadline_note/src/services/job_link_parser.dart';
import 'package:deadline_note/src/models/job_site.dart';

// Helper to access private method for testing (if possible, but can't access private methods directly)
// So rely on testParse behavior.

void main() {
  group('Indeed Blocked Page Handling', () {
    test('Should fallback to contextText when Indeed is blocked', () {
      final parser = JobLinkParser();
      final url = Uri.parse('https://kr.indeed.com/viewjob?jk=12345');
      final blockedHtml = '''
        <html>
          <head><title>Just a moment...</title></head>
          <body>
            <h1>Verify you are human</h1>
            <p>Cloudflare protection</p>
          </body>
        </html>
      ''';
      final contextText = 'Indeed에서 이 채용 공고를 확인해 보세요.\n삼성전자 - 반도체 설계 엔지니어\n서울';
      
      final result = parser.testParse(
        html_parser.parse(blockedHtml),
        'Just a moment...',
        'Verify you are human',
        contextText,
        '',
        url,
        JobSite.indeed,
      );

      print('Blocked Result Company: ${result.companyName}');
      print('Blocked Result Job: ${result.jobTitle}');
      print('Blocked Warnings: ${result.warnings}');

      expect(result.site, JobSite.indeed);
      expect(result.companyName, '삼성전자');
      expect(result.jobTitle, '반도체 설계 엔지니어');
      expect(result.warnings, isEmpty);
    });

    test('Should return empty with warning when blocked and no fallback', () {
      final parser = JobLinkParser();
      final url = Uri.parse('https://kr.indeed.com/viewjob?jk=12345');
      final blockedHtml = '''
        <html>
          <head><title>Just a moment...</title></head>
          <body>
            <h1>Verify you are human</h1>
          </body>
        </html>
      ''';
      
      final result = parser.testParse(
        html_parser.parse(blockedHtml),
        'Just a moment...',
        '',
        '',
        '',
        url,
        JobSite.indeed,
      );

      expect(result.site, JobSite.indeed);
      expect(result.companyName, isEmpty);
      expect(result.jobTitle, isEmpty);
      expect(result.warnings, contains('parseErrorMsg'));
    });

    test('Should NOT fallback if not blocked (Normal indeed page)', () {
      final parser = JobLinkParser();
      final url = Uri.parse('https://kr.indeed.com/viewjob?jk=12345');
      final normalHtml = '''
        <html>
          <head><title>Normal Job - Normal Company</title></head>
          <body>
            <div data-testid="jobsearch-JobInfoHeader-companyName">Normal Company</div>
            <h1 class="jobsearch-JobInfoHeader-title">Normal Job</h1>
          </body>
        </html>
      ''';
      final contextText = 'Indeed에서 이 채용 공고를 확인해 보세요.\nFallback Company - Fallback Job';
      
      final result = parser.testParse(
        html_parser.parse(normalHtml),
        'Normal Job - Normal Company',
        '',
        contextText,
        '',
        url,
        JobSite.indeed,
      );

      print('Normal Result Company: "${result.companyName}"');
      print('Normal Result Job: "${result.jobTitle}"');

      expect(result.site, JobSite.indeed);
      expect(result.companyName, 'Normal Company');
      expect(result.jobTitle, 'Normal Job');
    });
  });
}
