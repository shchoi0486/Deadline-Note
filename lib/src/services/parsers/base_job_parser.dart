import 'package:html/dom.dart' as dom;
import '../../models/deadline_type.dart';

typedef PartialJobData = ({
  String companyName,
  String jobTitle,
  DateTime? deadlineAt,
  DeadlineType deadlineType,
  String salary,
  bool isEstimated,
  DateTime? datePosted,
});

/// Base class for regional job parsers
abstract class BaseJobParser {
  PartialJobData parse(dom.Document doc, String title, String desc, String writer, Uri uri);
}
