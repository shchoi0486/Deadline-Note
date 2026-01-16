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
  String get label {
    switch (this) {
      case JobStatus.notApplied:
        return '지원 전';
      case JobStatus.applied:
        return '지원 완료';
      case JobStatus.document:
        return '서류';
      case JobStatus.videoInterview:
        return '인적성검사';
      case JobStatus.interview1:
        return '1차면접';
      case JobStatus.interview2:
        return '2차면접';
      case JobStatus.finalInterview:
        return '최종면접';
      case JobStatus.offer:
        return '오퍼';
      case JobStatus.hired:
        return '합격';
      case JobStatus.rejected:
        return '불합격';
      case JobStatus.closed:
        return '마감됨';
    }
  }

  String get badgeLabel {
    switch (this) {
      case JobStatus.document:
        return '서류';
      case JobStatus.videoInterview:
        return '인적성';
      case JobStatus.interview1:
        return '1차';
      case JobStatus.interview2:
        return '2차';
      case JobStatus.finalInterview:
        return '최종';
      case JobStatus.closed:
        return '마감';
      default:
        return '';
    }
  }
}

extension JobOutcomeLabels on JobOutcome {
  String get label {
    switch (this) {
      case JobOutcome.none:
        return '';
      case JobOutcome.passed:
        return '합격';
      case JobOutcome.failed:
        return '불합격';
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
