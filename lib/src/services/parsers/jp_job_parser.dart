import 'package:html/dom.dart' as dom;
import '../../models/job_site.dart';
import 'base_job_parser.dart';

class JpJobParser implements BaseJobParser {
  final PartialJobData Function(dom.Document, String, String, String, JobSite) parseGeneric;
  final PartialJobData Function(dom.Document, String, String, String) parseIndeedJp;
  final PartialJobData Function(dom.Document, String, String, String) parseRikunabi;
  final PartialJobData Function(dom.Document, String, String, String) parseMynavi;
  final PartialJobData Function(dom.Document, String, String, String) parseWantedly;
  final PartialJobData Function(dom.Document, String, String, String) parseDoda;
  final PartialJobData Function(dom.Document, String, String, String) parseEnJapan;
  final JobSite Function({
    required Uri uri,
    required String ogSiteName,
    required String title,
  }) detectSite;

  JpJobParser({
    required this.parseGeneric,
    required this.parseIndeedJp,
    required this.parseRikunabi,
    required this.parseMynavi,
    required this.parseWantedly,
    required this.parseDoda,
    required this.parseEnJapan,
    required this.detectSite,
  });

  @override
  PartialJobData parse(dom.Document doc, String title, String desc, String writer, Uri uri) {
    final host = uri.host.toLowerCase();

    if (host.contains('jp.indeed.com') || host.contains('indeed.co.jp')) {
      return parseIndeedJp(doc, title, desc, writer);
    }
    if (host.contains('rikunabi.com')) {
      return parseRikunabi(doc, title, desc, writer);
    }
    if (host.contains('mynavi.jp')) {
      return parseMynavi(doc, title, desc, writer);
    }
    if (host.contains('wantedly.com')) {
      return parseWantedly(doc, title, desc, writer);
    }
    if (host.contains('doda.jp')) {
      return parseDoda(doc, title, desc, writer);
    }
    if (host.contains('en-japan.com')) {
      return parseEnJapan(doc, title, desc, writer);
    }

    final site = detectSite(uri: uri, ogSiteName: '', title: title);
    return parseGeneric(doc, title, desc, writer, site);
  }
}
