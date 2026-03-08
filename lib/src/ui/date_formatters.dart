import 'package:intl/intl.dart';
import 'package:deadline_note/l10n/app_localizations.dart';

class DateFormatters {
  static final ymd = DateFormat('yyyy.MM.dd');

  static DateTime dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  static String dDayLabel(AppLocalizations l10n, DateTime deadlineAt, {DateTime? now}) {
    final base = now ?? DateTime.now();
    final days = dateOnly(deadlineAt).difference(dateOnly(base)).inDays;
    if (days == 0) return l10n.dDayToday;
    if (days > 0) return 'D-$days';
    return l10n.dDayClosed;
  }
}

