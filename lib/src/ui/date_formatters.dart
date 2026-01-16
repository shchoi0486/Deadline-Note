import 'package:intl/intl.dart';

class DateFormatters {
  static final ymd = DateFormat('yyyy.MM.dd');

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static String dDayLabel(DateTime deadlineAt, {DateTime? now}) {
    final base = now ?? DateTime.now();
    final days = dateOnly(deadlineAt).difference(dateOnly(base)).inDays;
    if (days == 0) return 'D-DAY';
    if (days > 0) return 'D-$days';
    return '마감';
  }
}

