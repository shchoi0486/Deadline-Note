import 'package:html/dom.dart' as dom;
import '../../models/job_site.dart';
import 'base_job_parser.dart';

class GlobalJobParser implements BaseJobParser {
  final PartialJobData Function(dom.Document, String, String, String, Uri) parseLinkedIn;
  final PartialJobData Function(dom.Document, String, String, String, Uri) parseIndeed;
  final PartialJobData Function(dom.Document, String, String, String, Uri) parseGlassdoor;
  final PartialJobData Function(dom.Document, String, String, String, Uri) parseMonster;
  final PartialJobData Function(dom.Document, String, String, String, Uri) parseCareerBuilder;
  final PartialJobData Function(dom.Document, String, String, String, JobSite) parseGeneric;
  final JobSite Function({required Uri uri, required String ogSiteName, required String title}) detectSite;

  GlobalJobParser({
    required this.parseLinkedIn,
    required this.parseIndeed,
    required this.parseGlassdoor,
    required this.parseMonster,
    required this.parseCareerBuilder,
    required this.parseGeneric,
    required this.detectSite,
  });

  @override
  PartialJobData parse(dom.Document doc, String title, String desc, String writer, Uri uri) {
    final site = detectSite(uri: uri, ogSiteName: '', title: title);
    
    if (site == JobSite.linkedin) {
      return parseLinkedIn(doc, title, desc, writer, uri);
    }
    if (site == JobSite.indeed) {
      return parseIndeed(doc, title, desc, writer, uri);
    }
    if (site == JobSite.glassdoor) {
      return parseGlassdoor(doc, title, desc, writer, uri);
    }
    if (site == JobSite.monster) {
      return parseMonster(doc, title, desc, writer, uri);
    }
    if (site == JobSite.careerbuilder) {
      return parseCareerBuilder(doc, title, desc, writer, uri);
    }
    
    return parseGeneric(doc, title, desc, writer, site);
  }
}
