import '../../l10n/app_localizations.dart';
import 'job_status.dart';
import 'job_site.dart';
import 'deadline_type.dart';

class JobDeadline {
  JobDeadline({
    required this.id,
    required this.companyName,
    required this.jobTitle,
    required this.deadlineAt,
    required this.deadlineType,
    required this.linkUrl,
    required this.site,
    required this.salary,
    required this.status,
    required this.outcome,
    required this.notificationsEnabled,
    required this.memo,
    required this.createdAt,
    this.isEstimated = false,
    this.previousStepId,
  });

  final String id;
  final String companyName;
  final String jobTitle;
  final DateTime deadlineAt;
  final DeadlineType deadlineType;
  final String linkUrl;
  final JobSite site;
  final String salary;
  final JobStatus status;
  final JobOutcome outcome;
  final bool notificationsEnabled;
  final String memo;
  final DateTime createdAt;
  final bool isEstimated;
  final String? previousStepId;

  String localizedDisplayStatusLabel(AppLocalizations l10n) {
    if (status == JobStatus.closed) return JobStatus.closed.localizedLabel(l10n);
    if (outcome != JobOutcome.none) return outcome.localizedLabel(l10n);
    return status.localizedLabel(l10n);
  }

  String get displayStatusLabel {
    if (status == JobStatus.closed) return JobStatus.closed.name;
    if (outcome != JobOutcome.none) return outcome.name;
    return status.name;
  }

  JobDeadline copyWith({
    String? id,
    String? companyName,
    String? jobTitle,
    DateTime? deadlineAt,
    DeadlineType? deadlineType,
    String? linkUrl,
    JobSite? site,
    String? salary,
    JobStatus? status,
    JobOutcome? outcome,
    bool? notificationsEnabled,
    String? memo,
    DateTime? createdAt,
    bool? isEstimated,
    String? previousStepId,
  }) {
    return JobDeadline(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      jobTitle: jobTitle ?? this.jobTitle,
      deadlineAt: deadlineAt ?? this.deadlineAt,
      deadlineType: deadlineType ?? this.deadlineType,
      linkUrl: linkUrl ?? this.linkUrl,
      site: site ?? this.site,
      salary: salary ?? this.salary,
      status: status ?? this.status,
      outcome: outcome ?? this.outcome,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
      isEstimated: isEstimated ?? this.isEstimated,
      previousStepId: previousStepId ?? this.previousStepId,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'companyName': companyName,
      'jobTitle': jobTitle,
      'deadlineAt': deadlineAt.toIso8601String(),
      'deadlineType': deadlineType.name,
      'linkUrl': linkUrl,
      'site': site.name,
      'salary': salary,
      'status': status.name,
      'outcome': outcome.name,
      'notificationsEnabled': notificationsEnabled,
      'memo': memo,
      'createdAt': createdAt.toIso8601String(),
      'isEstimated': isEstimated,
      'previousStepId': previousStepId,
    };
  }

  static JobDeadline fromJson(Map<String, Object?> json) {
    final siteName = (json['site'] as String?) ?? JobSite.unknown.name;
    final site = JobSite.values.firstWhere(
      (s) => s.name == siteName,
      orElse: () => JobSite.unknown,
    );

    final deadlineTypeName = (json['deadlineType'] as String?) ?? DeadlineType.fixedDate.name;
    final deadlineType = DeadlineType.values.firstWhere(
      (t) => t.name == deadlineTypeName,
      orElse: () => DeadlineType.fixedDate,
    );

    JobStatus parseStatus(Object? v) {
      final statusName = (v as String?)?.trim() ?? '';
      if (statusName.isEmpty) return JobStatus.notApplied;

      final byName = JobStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => JobStatus.notApplied,
      );
      if (byName != JobStatus.notApplied) return byName;

      final normalized = statusName.replaceAll(' ', '');
      final alias = <String, JobStatus>{
        '지원전': JobStatus.notApplied,
        '지원완료': JobStatus.applied,
        '서류': JobStatus.document,
        '화상면접': JobStatus.videoInterview,
        '인적성검사': JobStatus.videoInterview,
        '1차면접': JobStatus.interview1,
        '2차면접': JobStatus.interview2,
        '최종면접': JobStatus.finalInterview,
        '오퍼': JobStatus.offer,
        '입사': JobStatus.hired,
        '합격': JobStatus.hired,
        '불합격': JobStatus.rejected,
        '마감됨': JobStatus.closed,
        'video_interview': JobStatus.videoInterview,
        'video-interview': JobStatus.videoInterview,
      };
      final byAlias = alias[normalized] ?? alias[statusName];
      if (byAlias != null) return byAlias;

      final byLabel = JobStatus.values.firstWhere(
        (s) => s.internalLabel == statusName || s.internalLabel.replaceAll(' ', '') == normalized,
        orElse: () => JobStatus.notApplied,
      );
      return byLabel;
    }

    final rawStatus = parseStatus(json['status']);

    final outcomeName = (json['outcome'] as String?) ?? '';
    final rawOutcome = JobOutcome.values.firstWhere(
      (o) => o.name == outcomeName,
      orElse: () => JobOutcome.none,
    );

    final JobOutcome outcome;
    if (rawOutcome != JobOutcome.none) {
      outcome = rawOutcome;
    } else if (rawStatus == JobStatus.offer || rawStatus == JobStatus.hired) {
      outcome = JobOutcome.passed;
    } else if (rawStatus == JobStatus.rejected) {
      outcome = JobOutcome.failed;
    } else {
      outcome = JobOutcome.none;
    }

    final JobStatus status;
    if (rawStatus == JobStatus.notApplied || rawStatus == JobStatus.applied) {
      status = JobStatus.document;
    } else if (rawStatus == JobStatus.offer || rawStatus == JobStatus.hired || rawStatus == JobStatus.rejected) {
      status = JobStatus.finalInterview;
    } else if (rawStatus == JobStatus.closed) {
      status = JobStatus.closed;
    } else if (rawStatus.isPipelineStage) {
      status = rawStatus;
    } else {
      status = JobStatus.document;
    }

    return JobDeadline(
      id: (json['id'] as String?) ?? '',
      companyName: (json['companyName'] as String?) ?? '',
      jobTitle: (json['jobTitle'] as String?) ?? '',
      deadlineAt: DateTime.parse((json['deadlineAt'] as String?) ?? DateTime.now().toIso8601String()),
      deadlineType: deadlineType,
      linkUrl: (json['linkUrl'] as String?) ?? '',
      site: site,
      salary: (json['salary'] as String?) ?? '',
      status: status,
      outcome: outcome,
      notificationsEnabled: (json['notificationsEnabled'] as bool?) ?? true,
      memo: (json['memo'] as String?) ?? '',
      createdAt: DateTime.parse((json['createdAt'] as String?) ?? DateTime.now().toIso8601String()),
      isEstimated: (json['isEstimated'] as bool?) ?? false,
      previousStepId: json['previousStepId'] as String?,
    );
  }
}
