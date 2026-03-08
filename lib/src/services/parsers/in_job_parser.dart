import 'package:html/dom.dart' as dom;
import '../../models/job_site.dart';
import 'base_job_parser.dart';

class InJobParser implements BaseJobParser {
  final PartialJobData Function(dom.Document, String, String, String, JobSite) parseGeneric;
  final PartialJobData Function(dom.Document, String, String, String) parseNaukri;
  final PartialJobData Function(dom.Document, String, String, String) parseIndeedIndia;
  final PartialJobData Function(dom.Document, String, String, String) parseFoundit;
  final PartialJobData Function(dom.Document, String, String, String) parseShine;
  final PartialJobData Function(dom.Document, String, String, String) parseFreshersworld;
  final JobSite Function({
    required Uri uri,
    required String ogSiteName,
    required String title,
  }) detectSite;

  InJobParser({
    required this.parseGeneric,
    required this.parseNaukri,
    required this.parseIndeedIndia,
    required this.parseFoundit,
    required this.parseShine,
    required this.parseFreshersworld,
    required this.detectSite,
  });

  @override
  PartialJobData parse(dom.Document doc, String title, String desc, String writer, Uri uri) {
    final host = uri.host.toLowerCase();

    if (host.contains('naukri.com')) {
      return parseNaukri(doc, title, desc, writer);
    }
    if (host.contains('in.indeed.com') || host.contains('indeed.co.in')) {
      return parseIndeedIndia(doc, title, desc, writer);
    }
    if (host.contains('foundit.in') || host.contains('monsterindia.com')) {
      return parseFoundit(doc, title, desc, writer);
    }
    if (host.contains('shine.com')) {
      return parseShine(doc, title, desc, writer);
    }
    if (host.contains('freshersworld.com')) {
      return parseFreshersworld(doc, title, desc, writer);
    }

    final site = detectSite(uri: uri, ogSiteName: '', title: title);
    return parseGeneric(doc, title, desc, writer, site);
  }
}
