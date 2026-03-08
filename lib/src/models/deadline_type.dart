import 'package:deadline_note/l10n/app_localizations.dart';

enum DeadlineType {
  fixedDate, // 명시된 마감일
  rolling,   // 상시채용
  expired,   // 마감됨
  unknown,   // 정보 부족
}

extension DeadlineTypeLabels on DeadlineType {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case DeadlineType.fixedDate:
        return l10n.deadlineFixed;
      case DeadlineType.rolling:
        return l10n.deadlineRolling;
      case DeadlineType.expired:
        return l10n.deadlineExpired;
      case DeadlineType.unknown:
        return l10n.deadlineUnknown;
    }
  }
}
