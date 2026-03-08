import 'package:html/parser.dart' as html_parser;
import 'package:deadline_note/src/services/job_link_parser.dart';
import 'package:deadline_note/src/models/job_site.dart';
import 'package:deadline_note/src/models/deadline_type.dart';

void main() {
  final testCases = [
    {
      'name': 'Indeed - Rockefeller Capital Management',
      'url': 'https://www.indeed.com/viewjob?jk=rockefeller',
      'html': '''
        <html>
          <head><title>AI Software Developer - Rockefeller Capital Management</title></head>
          <body>
            <div class="jobsearch-JobInfoHeader-companyName">Rockefeller Capital Management</div>
            <h1 class="jobsearch-JobInfoHeader-title">AI Software Developer</h1>
            <div class="jobsearch-JobDescriptionSection">
              Compensation Range: The anticipated base salary range for this role is \$125,000 to \$140,000.
            </div>
            <div>EmployerActive 2 days ago</div>
          </body>
        </html>
      ''',
      'expected': {
        'company': 'Rockefeller Capital Management',
        'title': 'AI Software Developer',
        'salary': r'$125,000 to $140,000',
        'deadlineType': DeadlineType.rolling,
      }
    },
    {
      'name': 'Generic English - Retirement Clearinghouse',
      'url': 'https://example.com/jobs/dev',
      'html': '''
        <html>
          <head><title>Software Developer - Hybrid at Retirement Clearinghouse</title></head>
          <body>
            <div class="company-name">Retirement Clearinghouse</div>
            <h1>Software Developer—Hybrid Work Opportunity</h1>
            <p>Salary Range: \$100k-110k annually</p>
            <p>Apply as soon as possible. Rolling applications.</p>
          </body>
        </html>
      ''',
      'expected': {
        'company': 'Retirement Clearinghouse',
        'title': 'Software Developer—Hybrid Work Opportunity',
        'salary': r'$100k-110k annually',
        'deadlineType': DeadlineType.rolling,
      }
    },
    {
      'name': 'LinkedIn Style - Software Engineer at Google',
      'url': 'https://www.linkedin.com/jobs/view/12345',
      'html': '''
        <html>
          <head><title>Software Engineer at Google | LinkedIn</title></head>
          <body>
            <div class="top-card-layout__card">
              <h1 class="top-card-layout__title">Software Engineer</h1>
              <a class="top-card-layout__company-name">Google</a>
            </div>
            <div class="description">
              Hiring now! 50 applicants.
            </div>
          </body>
        </html>
      ''',
      'expected': {
        'company': 'Google',
        'title': 'Software Engineer',
        'deadlineType': DeadlineType.rolling,
      }
    }
  ];

  print('--- Starting Multilingual Job Link Parser Tests ---\n');

  final parser = JobLinkParser();
  int passedCount = 0;

  for (var tc in testCases) {
    final tcName = tc['name'] as String;
    print('Testing: $tcName');
    final doc = html_parser.parse(tc['html']);
    final uri = Uri.parse(tc['url'] as String);
    final title = doc.querySelector('title')?.text ?? '';
    final description = doc.body?.text ?? '';
    
    // Simulate site detection
    JobSite site = JobSite.unknown;
    if (uri.host.contains('indeed.com')) site = JobSite.indeed;
    if (uri.host.contains('linkedin.com')) site = JobSite.linkedin;

    try {
      final result = parser.testParse(doc, title, description, description, '', uri, site);
      final expected = tc['expected'] as Map<String, dynamic>;
      
      bool success = true;
      if (result.companyName != expected['company']) {
        final got = result.companyName;
        final want = expected['company'];
        print('  [FAIL] Company: Got "$got", Expected "$want"');
        success = false;
      }
      
      if (expected.containsKey('title') && result.jobTitle != expected['title']) {
        final got = result.jobTitle;
        final want = expected['title'];
        print('  [FAIL] Title: Got "$got", Expected "$want"');
        success = false;
      }

      if (expected.containsKey('salary')) {
        final expectedSalary = (expected['salary'] as String).replaceAll(RegExp(r'[\s,]'), '');
        final actualSalary = result.salary.replaceAll(RegExp(r'[\s,]'), '');
        if (!actualSalary.contains(expectedSalary)) {
           final got = result.salary;
           print('  [FAIL] Salary: Got "$got", Expected to contain "${expected['salary']}"');
           success = false;
        }
      }

      if (result.deadlineType != expected['deadlineType']) {
        final got = result.deadlineType;
        final want = expected['deadlineType'];
        print('  [FAIL] DeadlineType: Got $got, Expected $want');
        success = false;
      }

      if (success) {
        print('  [PASS]');
        passedCount++;
      }
    } catch (e) {
      print('  [ERROR] Exception during test: $e');
    }
    print('');
  }

  print('--- Test Results: $passedCount/${testCases.length} Passed ---');
}
