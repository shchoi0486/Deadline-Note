import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/deadline_type.dart';
import '../models/job_deadline.dart';
import '../models/job_site.dart';
import '../models/job_status.dart';
import '../services/job_link_parser.dart';
import '../services/notifications_service.dart';
import '../services/share_service.dart';
import '../services/storage_service.dart';

class AppSettings {
  AppSettings({
    required this.enableD3,
    required this.enableD1,
    required this.enable3h,
    this.adsRemoved = false,
    this.hasSeenOnboarding = false,
    this.holidayCountryCode,
    this.localeCode,
    this.stageColors = const {},
  });

  final bool enableD3;
  final bool enableD1;
  final bool enable3h;
  final bool adsRemoved;
  final bool hasSeenOnboarding;
  final String? holidayCountryCode;
  final String? localeCode;
  final Map<String, int> stageColors;

  AppSettings copyWith({
    bool? enableD3,
    bool? enableD1,
    bool? enable3h,
    bool? adsRemoved,
    bool? hasSeenOnboarding,
    Object? holidayCountryCode = _sentinel,
    Object? localeCode = _sentinel,
    Map<String, int>? stageColors,
  }) {
    return AppSettings(
      enableD3: enableD3 ?? this.enableD3,
      enableD1: enableD1 ?? this.enableD1,
      enable3h: enable3h ?? this.enable3h,
      adsRemoved: adsRemoved ?? this.adsRemoved,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      holidayCountryCode: holidayCountryCode == _sentinel
          ? this.holidayCountryCode
          : holidayCountryCode as String?,
      localeCode: localeCode == _sentinel ? this.localeCode : localeCode as String?,
      stageColors: stageColors ?? this.stageColors,
    );
  }

  static const _sentinel = Object();

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'enableD3': enableD3,
      'enableD1': enableD1,
      'enable3h': enable3h,
      'adsRemoved': adsRemoved,
      'hasSeenOnboarding': hasSeenOnboarding,
      'holidayCountryCode': holidayCountryCode,
      'localeCode': localeCode,
      'stageColors': stageColors,
    };
  }

  static AppSettings fromJson(Map<String, Object?> json) {
    final colors = (json['stageColors'] as Map?)?.cast<String, int>() ?? {
      'document': 0xFFC1E1FF, // Blue
      'videoInterview': 0xFFFFC1DC, // Pink
      'interview1': 0xFFE1C1FF, // Purple
      'interview2': 0xFFE1C1FF, // Purple
      'finalInterview': 0xFFE1C1FF, // Purple
    };
    return AppSettings(
      enableD3: (json['enableD3'] as bool?) ?? true,
      enableD1: (json['enableD1'] as bool?) ?? true,
      enable3h: (json['enable3h'] as bool?) ?? false,
      adsRemoved: (json['adsRemoved'] as bool?) ?? false,
      hasSeenOnboarding: (json['hasSeenOnboarding'] as bool?) ?? false,
      holidayCountryCode: json['holidayCountryCode'] as String?,
      localeCode: json['localeCode'] as String?,
      stageColors: colors,
    );
  }
}

class AppState extends ChangeNotifier {
  AppState({
    required StorageService storage,
    required NotificationsService notifications,
    required ShareService shareService,
    required JobLinkParser parser,
  })  : _storage = storage,
        _notifications = notifications,
        _shareService = shareService,
        _parser = parser;

  final StorageService _storage;
  final NotificationsService _notifications;
  final ShareService _shareService;
  final JobLinkParser _parser;

  List<JobDeadline> _deadlines = <JobDeadline>[];
  AppSettings _settings = AppSettings(enableD3: true, enableD1: true, enable3h: false);
  Map<String, String> _lastVisitedUrls = {};
  int _lastSavedRevision = 0;
  DateTime? _lastSavedDeadlineAt;

  List<JobDeadline> get deadlines => List<JobDeadline>.unmodifiable(_deadlines);
  AppSettings get settings => _settings;
  Map<String, String> get lastVisitedUrls => _lastVisitedUrls;
  int get lastSavedRevision => _lastSavedRevision;
  DateTime? get lastSavedDeadlineAt => _lastSavedDeadlineAt;

  Stream<String> get sharedTextStream => _shareService.onSharedText();

  final StreamController<void> _calendarResetController = StreamController<void>.broadcast();
  Stream<void> get onCalendarReset => _calendarResetController.stream;

  final StreamController<int> _tabChangeController = StreamController<int>.broadcast();
  Stream<int> get onTabChange => _tabChangeController.stream;

  void triggerCalendarReset() {
    _calendarResetController.add(null);
  }

  void jumpToTab(int index) {
    _tabChangeController.add(index);
  }

  Future<void> init() async {
    // 알림 권한 요청은 초기화 흐름을 방해하지 않도록 비동기로 실행하거나 타임아웃 처리
    unawaited(_notifications.requestPermissionsIfNeeded().catchError((e) {
      debugPrint('Permission request error: $e');
    }));

    _deadlines = await _storage.loadDeadlines();
    _settings = AppSettings.fromJson(await _storage.loadSettings());
    _lastVisitedUrls = await _storage.loadLastVisitedUrls();
    _deadlines = _normalizeClosed(_deadlines);
    await _storage.saveDeadlines(_deadlines);
    notifyListeners();
  }

  Future<void> updateLastVisitedUrl(String siteName, String url) async {
    _lastVisitedUrls = Map<String, String>.from(_lastVisitedUrls);
    _lastVisitedUrls[siteName] = url;
    await _storage.saveLastVisitedUrls(_lastVisitedUrls);
    notifyListeners();
  }

  Future<String?> getInitialSharedText() => _shareService.getInitialSharedText();

  Future<ParsedJobLink> parseSharedUrl(String rawUrl, {String? sharedText}) =>
      _parser.parse(rawUrl, contextText: sharedText);

  JobDeadline createDeadlineFromParsed(ParsedJobLink parsed) {
    final now = DateTime.now();
    final link = parsed.url.toString();
    final id = link.trim().isEmpty ? _randomId(now) : 'link-${_stableId(link)}';
    final deadlineAt = parsed.deadlineAt ?? DateTime(now.year, now.month, now.day, 23, 59);
    final isEstimated = parsed.deadlineAt == null || parsed.isEstimated;

    return JobDeadline(
      id: id,
      companyName: parsed.companyName,
      jobTitle: parsed.jobTitle,
      deadlineAt: deadlineAt,
      deadlineType: parsed.deadlineType,
      linkUrl: link,
      site: parsed.site,
      salary: parsed.salary,
      status: JobStatus.document,
      outcome: JobOutcome.none,
      notificationsEnabled: true,
      memo: '',
      createdAt: now,
      isEstimated: isEstimated,
    );
  }

  Future<void> upsertDeadline(JobDeadline deadline, {bool incrementRevision = true}) async {
    final next = <JobDeadline>[
      for (final d in _deadlines)
        if (d.id == deadline.id) deadline else d,
      if (_deadlines.every((d) => d.id != deadline.id)) deadline,
    ];

    _deadlines = _normalizeClosed(next)..sort((a, b) => a.deadlineAt.compareTo(b.deadlineAt));
    await _storage.saveDeadlines(_deadlines);
    await _notifications.scheduleForDeadline(
      deadline: deadline,
      enableD3: _settings.enableD3,
      enableD1: _settings.enableD1,
      enable3h: _settings.enable3h,
    );
    _lastSavedDeadlineAt = deadline.deadlineAt;
    if (incrementRevision) {
      _lastSavedRevision += 1;
    }
    notifyListeners();
  }

  Future<void> deleteDeadline(String id) async {
    final target = _deadlines.where((d) => d.id == id).firstOrNull;
    if (target == null) return;

    final prevId = target.previousStepId;

    _deadlines = _deadlines.where((d) => d.id != id).toList(growable: false);

    if (prevId != null) {
      // 이전 단계의 합격 상태를 해제 (다음 일정을 삭제했으므로)
      _deadlines = _deadlines.map((d) {
        if (d.id == prevId) {
          return d.copyWith(outcome: JobOutcome.none);
        }
        return d;
      }).toList(growable: false);
    }

    await _storage.saveDeadlines(_deadlines);
    await _notifications.cancelForDeadline(id);
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    await _storage.saveSettings(_settings.toJson());

    // Schedule notifications in parallel to avoid blocking for too long
    // Note: If the list is very large, we might want to chunk this, 
    // but for typical usage (<100 items), Future.wait is fine.
    await Future.wait(_deadlines.map((d) => _notifications.scheduleForDeadline(
      deadline: d,
      enableD3: _settings.enableD3,
      enableD1: _settings.enableD1,
      enable3h: _settings.enable3h,
    )));

    notifyListeners();
  }

  JobDeadline createBlankDeadline() {
    final now = DateTime.now();
    final id = _randomId(now);
    return JobDeadline(
      id: id,
      companyName: '',
      jobTitle: '',
      deadlineAt: DateTime(now.year, now.month, now.day, 18, 0),
      deadlineType: DeadlineType.fixedDate,
      linkUrl: '',
      site: JobSite.unknown,
      salary: '',
      status: JobStatus.document,
      outcome: JobOutcome.none,
      notificationsEnabled: true,
      memo: '',
      createdAt: now,
      isEstimated: false,
    );
  }

  String _randomId(DateTime now) {
    return '${now.microsecondsSinceEpoch}-${Random().nextInt(9999).toString().padLeft(4, '0')}';
  }

  int _stableId(String input) {
    var hash = 0x811c9dc5;
    for (final codeUnit in input.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  List<JobDeadline> _normalizeClosed(List<JobDeadline> input) {
    final now = DateTime.now();
    return input
        .map((d) {
          final isPast = d.deadlineAt.isBefore(DateTime(now.year, now.month, now.day));
          final keep = d.status == JobStatus.closed || d.outcome != JobOutcome.none;
          if (isPast && !keep) {
            return d.copyWith(status: JobStatus.closed);
          }
          return d;
        })
        .toList(growable: false);
  }

  @override
  void dispose() {
    _shareService.dispose();
    super.dispose();
  }
}
