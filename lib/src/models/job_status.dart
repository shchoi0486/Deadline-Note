import 'package:deadline_note/l10n/app_localizations.dart';

enum JobStatus {
  notApplied,
  applied,
  document,
  videoInterview,
  interview1,
  interview2,
  finalInterview,
  offer,
  hired,
  rejected,
  closed,
}

enum JobOutcome {
  none,
  passed,
  failed,
}

extension JobStatusLabels on JobStatus {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case JobStatus.notApplied:
        return l10n.statusNotApplied;
      case JobStatus.applied:
        return l10n.statusApplied;
      case JobStatus.document:
        return l10n.statusDocument;
      case JobStatus.videoInterview:
        return l10n.statusVideoInterview;
      case JobStatus.interview1:
        return l10n.statusInterview1;
      case JobStatus.interview2:
        return l10n.statusInterview2;
      case JobStatus.finalInterview:
        return l10n.statusFinalInterview;
      case JobStatus.offer:
        return l10n.statusOffer;
      case JobStatus.hired:
        return l10n.statusHired;
      case JobStatus.rejected:
        return l10n.statusRejected;
      case JobStatus.closed:
        return l10n.statusClosed;
    }
  }

  /// Internal use only for legacy data parsing. Use [localizedLabel] for UI.
  String get internalLabel {
    switch (this) {
      case JobStatus.notApplied:
        return '지원전';
      case JobStatus.applied:
        return '지원완료';
      case JobStatus.document:
        return '서류';
      case JobStatus.videoInterview:
        return '화상면접';
      case JobStatus.interview1:
        return '1차면접';
      case JobStatus.interview2:
        return '2차면접';
      case JobStatus.finalInterview:
        return '최종면접';
      case JobStatus.offer:
        return '오퍼';
      case JobStatus.hired:
        return '입사';
      case JobStatus.rejected:
        return '불합격';
      case JobStatus.closed:
        return '마감됨';
    }
  }

  String localizedBadgeLabel(AppLocalizations l10n) {
    switch (this) {
      case JobStatus.document:
        return l10n.badgeDocument;
      case JobStatus.videoInterview:
        return l10n.badgeVideoInterview;
      case JobStatus.interview1:
        return l10n.badgeInterview1;
      case JobStatus.interview2:
        return l10n.badgeInterview2;
      case JobStatus.finalInterview:
        return l10n.badgeFinalInterview;
      case JobStatus.closed:
        return l10n.badgeClosed;
      default:
        return '';
    }
  }
}

extension JobOutcomeLabels on JobOutcome {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case JobOutcome.none:
        return '';
      case JobOutcome.passed:
        return l10n.outcomePassed;
      case JobOutcome.failed:
        return l10n.outcomeFailed;
    }
  }
}

const List<JobStatus> kPipelineStageOptions = <JobStatus>[
  JobStatus.document,
  JobStatus.videoInterview,
  JobStatus.interview1,
  JobStatus.interview2,
  JobStatus.finalInterview,
];

extension JobStatusStageChecks on JobStatus {
  bool get isPipelineStage =>
      this == JobStatus.document ||
      this == JobStatus.videoInterview ||
      this == JobStatus.interview1 ||
      this == JobStatus.interview2 ||
      this == JobStatus.finalInterview;
}

extension JobStatusGroups on JobStatus {
  bool get isAppliedGroup => this == JobStatus.applied || this == JobStatus.document;

  bool get isInterviewGroup =>
      this == JobStatus.videoInterview ||
      this == JobStatus.interview1 ||
      this == JobStatus.interview2 ||
      this == JobStatus.finalInterview;

  bool get isSuccessGroup => this == JobStatus.offer || this == JobStatus.hired;
}
