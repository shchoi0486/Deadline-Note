import 'package:html/dom.dart' as dom;
import '../../models/job_site.dart';
import 'base_job_parser.dart';

class KrJobParser implements BaseJobParser {
  final PartialJobData Function(dom.Document, String, String, String) parseJobKorea;
  final PartialJobData Function(dom.Document, String, String, String) parseSaramin;
  final PartialJobData Function(dom.Document, String, String, String) parseIncruit;
  final PartialJobData Function(dom.Document, String, String, String) parseAlbamon;
  final PartialJobData Function(dom.Document, String, String, String) parseAlbaheaven;
  final PartialJobData Function(dom.Document, String, String, String) parseWanted;
  final PartialJobData Function(dom.Document, String, String, String, JobSite) parseGeneric;
  final JobSite Function({required Uri uri, required String ogSiteName, required String title}) detectSite;

  KrJobParser({
    required this.parseJobKorea,
    required this.parseSaramin,
    required this.parseIncruit,
    required this.parseAlbamon,
    required this.parseAlbaheaven,
    required this.parseWanted,
    required this.parseGeneric,
    required this.detectSite,
  });

  @override
  PartialJobData parse(dom.Document doc, String title, String desc, String writer, Uri uri) {
    final site = detectSite(uri: uri, ogSiteName: '', title: title);
    
    switch (site) {
      case JobSite.jobkorea:
        return parseJobKorea(doc, title, desc, writer);
      case JobSite.saramin:
        return parseSaramin(doc, title, desc, writer);
      case JobSite.incruit:
        return parseIncruit(doc, title, desc, writer);
      case JobSite.albamon:
        return parseAlbamon(doc, title, desc, writer);
      case JobSite.albaheaven:
        return parseAlbaheaven(doc, title, desc, writer);
      case JobSite.wanted:
        return parseWanted(doc, title, desc, writer);
      default:
        return parseGeneric(doc, title, desc, writer, site);
    }
  }
}
