import 'package:html/dom.dart' as dom;
import '../../models/job_site.dart';
import 'base_job_parser.dart';

class CnJobParser implements BaseJobParser {
  final PartialJobData Function(dom.Document, String, String, String, JobSite) parseGeneric;
  final PartialJobData Function(dom.Document, String, String, String) parse51Job;
  final PartialJobData Function(dom.Document, String, String, String) parseZhaopin;
  final PartialJobData Function(dom.Document, String, String, String) parseBossZhipin;
  final PartialJobData Function(dom.Document, String, String, String) parseLiepin;
  final PartialJobData Function(dom.Document, String, String, String) parseLagou;
  final JobSite Function({
    required Uri uri,
    required String ogSiteName,
    required String title,
  }) detectSite;

  CnJobParser({
    required this.parseGeneric,
    required this.parse51Job,
    required this.parseZhaopin,
    required this.parseBossZhipin,
    required this.parseLiepin,
    required this.parseLagou,
    required this.detectSite,
  });

  @override
  PartialJobData parse(dom.Document doc, String title, String desc, String writer, Uri uri) {
    final host = uri.host.toLowerCase();

    if (host.contains('51job.com')) {
      return parse51Job(doc, title, desc, writer);
    }
    if (host.contains('zhaopin.com')) {
      return parseZhaopin(doc, title, desc, writer);
    }
    if (host.contains('zhipin.com')) {
      return parseBossZhipin(doc, title, desc, writer);
    }
    if (host.contains('liepin.com')) {
      return parseLiepin(doc, title, desc, writer);
    }
    if (host.contains('lagou.com')) {
      return parseLagou(doc, title, desc, writer);
    }

    final site = detectSite(uri: uri, ogSiteName: '', title: title);
    return parseGeneric(doc, title, desc, writer, site);
  }
}
