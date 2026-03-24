import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:deadline_note/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

import '../models/deadline_type.dart';
import '../models/job_deadline.dart';
import '../models/job_status.dart';
import '../state/app_state_scope.dart';
import '../ui/date_formatters.dart';
import '../widgets/ad_placeholder.dart';
import 'add_manual_screen.dart';
import 'deadline_detail_screen.dart';

enum _CalendarViewMode { month, week, list }
enum _ExpansionState { calendarFull, half, agendaFull }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _handledSavedRevision = 0;
  String? _lastHandledCountryCode;
  static const _saturdayBlue = Color(0xFF2563EB);
  static const _docPink = Color(0xFFFFC1DC);
  static const _aptOrange = Color(0xFFFFD59E);
  static const _interviewGreen = Color(0xFFB7F0C0);
  final Map<int, Set<String>> _holidayFetchedByYear = {};
  final Set<int> _holidayFetchInFlight = {};
  
  _CalendarViewMode _viewMode = _CalendarViewMode.month;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  StreamSubscription? _resetSub;
  _ExpansionState _expansionState = _ExpansionState.half;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateFormatters.dateOnly(DateTime.now());
    _ensureHolidaysForYear(_focusedDay.year);
  }

  void _onFocusedDayChanged(DateTime focusedDay) {
    if (_focusedDay.year != focusedDay.year) {
      _ensureHolidaysForYear(focusedDay.year);
    }
    setState(() {
      _focusedDay = focusedDay;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resetSub?.cancel();
    final appState = AppStateScope.of(context);
    
    // 국가 설정이 변경되었을 때 기존 공휴일 캐시 초기화 및 다시 불러오기
    final countryCode = appState.settings.holidayCountryCode ?? 
        Localizations.localeOf(context).countryCode ?? 
        'KR';
    if (_lastHandledCountryCode != countryCode) {
      _lastHandledCountryCode = countryCode;
      _holidayFetchedByYear.clear();
      _ensureHolidaysForYear(_focusedDay.year);
    }

    _resetSub = appState.onCalendarReset.listen((_) {
      if (!mounted) return;
      setState(() {
        _focusedDay = DateTime.now();
        _selectedDay = DateFormatters.dateOnly(DateTime.now());
        // 월간 달력 보기로 리셋
        _viewMode = _CalendarViewMode.month;
        _calendarFormat = CalendarFormat.month;
        _expansionState = _ExpansionState.half;
      });
    });

    // 데이터 저장 시 해당 날짜로 이동 및 선택 처리
    final savedAt = appState.lastSavedDeadlineAt;
    final savedRevision = appState.lastSavedRevision;
    if (savedAt != null && savedRevision != _handledSavedRevision) {
      _handledSavedRevision = savedRevision;
      // build 도중이 아니므로 바로 setState 가능하지만, 
      // 일관성을 위해 postFrameCallback 유지하거나 직접 호출
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final dayOnly = DateFormatters.dateOnly(savedAt);
        _onFocusedDayChanged(dayOnly);
        setState(() {
          _selectedDay = dayOnly;
        });
      });
    }
  }

  @override
  void dispose() {
    _resetSub?.cancel();
    super.dispose();
  }

  static String _ymdKey(DateTime day) => '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  static bool _isFixedHoliday(DateTime day) {
    final m = day.month;
    final d = day.day;
    if (m == 1 && d == 1) return true;
    if (m == 12 && d == 25) return true;
    return false;
  }

  bool _isHoliday(DateTime day) {
    final key = _ymdKey(DateFormatters.dateOnly(day));
    final fetched = _holidayFetchedByYear[day.year];
    if (fetched != null && fetched.contains(key)) return true;
    return _isFixedHoliday(day);
  }

  Color _stageColorFor(JobDeadline job, ColorScheme cs) {
    final settings = AppStateScope.of(context).settings;
    final customColor = settings.stageColors[job.status.name];
    if (customColor != null) return Color(customColor);

    if (job.status == JobStatus.document) return _docPink;
    if (job.status == JobStatus.videoInterview) return _aptOrange;
    if (job.status.isInterviewGroup) return _interviewGreen;
    if (job.status == JobStatus.closed) return cs.surfaceContainerHighest;
    return cs.surfaceContainerLow;
  }

  Color? _dayTextColor(BuildContext context, DateTime day) {
    final cs = Theme.of(context).colorScheme;
    if (_isHoliday(day) || day.weekday == DateTime.sunday) return cs.error;
    if (day.weekday == DateTime.saturday) return _saturdayBlue;
    return null;
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day, {
    required List<JobDeadline> items,
    required bool isSelected,
    required bool isToday,
    required bool isOutside,
    required bool isHoliday,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final baseTextColor = _dayTextColor(context, day) ?? cs.onSurface;
    final numberColor = isOutside ? baseTextColor.withOpacity(0.35) : baseTextColor;
    final selectedBg = cs.surfaceContainerHigh;

    Widget dayNumber() {
      final isTodayText = isToday;
      return Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: isTodayText
            ? BoxDecoration(
                color: cs.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              )
            : null,
        child: Text(
          '${day.day}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: isTodayText ? cs.onPrimary : numberColor,
            fontWeight: isTodayText ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      );
    }

    Color stageColor(JobDeadline job) => _stageColorFor(job, cs);

    String chipTitle(JobDeadline job) {
      return job.companyName.isNotEmpty ? job.companyName : (job.jobTitle.isNotEmpty ? job.jobTitle : l10n.defaultScheduleTitle);
    }

    return SizedBox.expand(
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: isSelected ? 1.01 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(3, 3, 3, 2),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? cs.primary.withOpacity(0.2) 
                  : const Color(0xFFF0F0F0).withOpacity(0.5),
              width: isSelected ? 1.5 : 0.5,
            ),
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                dayNumber(),
                const SizedBox(height: 2),
                if (items.isNotEmpty)
                  Wrap(
                    spacing: 0,
                    runSpacing: 1.5,
                    alignment: WrapAlignment.center,
                    children: items.map((job) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0.5),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: stageColor(job),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          chipTitle(job),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w800,
                            fontSize: 7.5,
                            height: 1.1,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _ensureHolidaysForYear(int year) async {
    if (_holidayFetchedByYear.containsKey(year)) return;
    if (_holidayFetchInFlight.contains(year)) return;
    _holidayFetchInFlight.add(year);
    try {
      final appState = AppStateScope.of(context);
      final countryCode = appState.settings.holidayCountryCode ?? View.of(context).platformDispatcher.locale.countryCode ?? 'KR';
      
      final uri = Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$year/$countryCode');
      final response = await http.get(uri);
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      
      final next = await compute(_parseHolidayJson, response.body);
      
      if (!mounted) return;
      setState(() {
        _holidayFetchedByYear[year] = next;
      });
    } catch (_) {
    } finally {
      _holidayFetchInFlight.remove(year);
    }
  }

  void _showStageColorSettings(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final appState = AppStateScope.of(context);

    final stages = [
      JobStatus.document,
      JobStatus.videoInterview,
      JobStatus.interview1,
      JobStatus.interview2,
      JobStatus.finalInterview,
    ];

    final colorOptions = [
      const Color(0xFFFFC1DC), // Pink
      const Color(0xFFFFD59E), // Orange
      const Color(0xFFB7F0C0), // Green
      const Color(0xFFC1E1FF), // Blue
      const Color(0xFFE1C1FF), // Purple
      const Color(0xFFFFE1C1), // Peach
      const Color(0xFFC1FFF0), // Mint
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentSettings = AppStateScope.of(context).settings;
            
            return AlertDialog(
              title: Text(
                l10n.colorSetting,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: stages.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 24),
                  itemBuilder: (context, index) {
                    final stage = stages[index];
                    final selectedColorValue = currentSettings.stageColors[stage.name];
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stage.localizedLabel(l10n),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: cs.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final color in colorOptions)
                              GestureDetector(
                                onTap: () {
                                  final newColors = Map<String, int>.from(currentSettings.stageColors);
                                  newColors[stage.name] = color.toARGB32();
                                  appState.updateSettings(currentSettings.copyWith(stageColors: newColors));
                                  setDialogState(() {});
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: selectedColorValue == color.toARGB32()
                                          ? cs.primary
                                          : Colors.grey.withOpacity(0.2),
                                      width: selectedColorValue == color.toARGB32() ? 2.5 : 1,
                                    ),
                                    boxShadow: [
                                      if (selectedColorValue == color.toARGB32())
                                        BoxShadow(
                                          color: cs.primary.withOpacity(0.2),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                    ],
                                  ),
                                  child: selectedColorValue == color.toARGB32()
                                      ? Icon(Icons.check, size: 18, color: cs.primary)
                                      : null,
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.ok),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openAgenda() async {
    if (!mounted) return;
    if (_viewMode != _CalendarViewMode.month) return;
    setState(() {
      if (_expansionState == _ExpansionState.calendarFull) {
        _expansionState = _ExpansionState.half;
      } else {
        _expansionState = _ExpansionState.agendaFull;
      }
    });
  }

  void _handleExpansionGesture(double velocity) {
    if (_viewMode != _CalendarViewMode.month) return;
    if (velocity > 300) { // Swipe down
      setState(() {
        if (_expansionState == _ExpansionState.agendaFull) {
          _expansionState = _ExpansionState.half;
        } else {
          _expansionState = _ExpansionState.calendarFull;
        }
      });
    } else if (velocity < -300) { // Swipe up
      setState(() {
        if (_expansionState == _ExpansionState.calendarFull) {
          _expansionState = _ExpansionState.half;
        } else {
          _expansionState = _ExpansionState.agendaFull;
        }
      });
    }
  }

  void _toggleViewMode() {
    setState(() {
      if (_viewMode == _CalendarViewMode.month) {
        _viewMode = _CalendarViewMode.week;
        _calendarFormat = CalendarFormat.week;
        _expansionState = _ExpansionState.calendarFull;
      } else if (_viewMode == _CalendarViewMode.week) {
        _viewMode = _CalendarViewMode.list;
        _expansionState = _ExpansionState.calendarFull;
      } else {
        _viewMode = _CalendarViewMode.month;
        _calendarFormat = CalendarFormat.month;
        _expansionState = _ExpansionState.half;
      }
    });
  }

  static DateTime _weekStart(DateTime day) {
    final d = DateFormatters.dateOnly(day);
    return d.subtract(Duration(days: d.weekday % 7));
  }

  Widget _buildWeekView(Map<DateTime, List<JobDeadline>> byDate) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();

    final anchor = DateFormatters.dateOnly(_selectedDay ?? _focusedDay);
    final start = _weekStart(anchor);
    final days = List<DateTime>.generate(7, (i) => start.add(Duration(days: i)), growable: false);

    Color stageColor(JobDeadline job) => _stageColorFor(job, cs);

    void moveWeek(int deltaWeeks) {
      final base = DateFormatters.dateOnly(_selectedDay ?? _focusedDay);
      final next = base.add(Duration(days: 7 * deltaWeeks));
      if (_focusedDay.year != next.year) {
        _ensureHolidaysForYear(next.year);
      }
      setState(() {
        _focusedDay = next;
        _selectedDay = next;
      });
    }

    String titleFor(JobDeadline job) {
      return job.companyName.isNotEmpty ? job.companyName : (job.jobTitle.isNotEmpty ? job.jobTitle : l10n.defaultScheduleTitle);
    }

    Color badgeBgFor(JobDeadline job) {
      if (job.status == JobStatus.closed) return cs.surfaceContainerHighest;
      return stageColor(job);
    }

    Color badgeFgFor(JobDeadline job) {
      if (job.status == JobStatus.closed) return cs.onSurfaceVariant;
      return cs.onSurface;
    }

    Widget badge(JobDeadline job) {
      return Container(
        width: 42,
        height: 18,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: badgeBgFor(job),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          job.status.localizedBadgeLabel(l10n),
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: theme.textTheme.labelSmall?.copyWith(
            color: badgeFgFor(job),
            fontWeight: FontWeight.w900,
            fontSize: 10,
            height: 1.0,
            letterSpacing: -0.2,
          ),
        ),
      );
    }

    Widget chip(JobDeadline job) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => DeadlineDetailScreen(deadlineId: job.id)),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.45)),
          ),
          child: Row(
            children: [
              badge(job),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titleFor(job),
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final dx = details.velocity.pixelsPerSecond.dx;
        if (dx.abs() < 250) return;
        if (dx < 0) {
          moveWeek(1);
        } else {
          moveWeek(-1);
        }
      },
      child: Column(
        children: [
          for (var index = 0; index < days.length; index++)
            Expanded(
              child: Builder(
                builder: (context) {
                  final day = days[index];
                  final dayOnly = DateFormatters.dateOnly(day);
                  final isSelected = _selectedDay != null && DateFormatters.dateOnly(_selectedDay!) == dayOnly;
                  final isOutside = dayOnly.month != anchor.month;

                  final baseTextColor = _dayTextColor(context, dayOnly) ?? cs.onSurface;
                  final numberColor = isOutside ? baseTextColor.withOpacity(0.35) : baseTextColor;

                  final items = List<JobDeadline>.from(byDate[dayOnly] ?? const <JobDeadline>[])
                    ..sort((a, b) => a.deadlineAt.compareTo(b.deadlineAt));
                  
                  final chipsView = items.isEmpty
                      ? const SizedBox.shrink()
                      : Wrap(
                          spacing: 0,
                          runSpacing: 4,
                          alignment: WrapAlignment.start,
                          children: items.map((job) => Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: chip(job),
                          )).toList(),
                        );

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDay = dayOnly;
                        _focusedDay = dayOnly;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? cs.surfaceContainerHigh : null,
                        border: Border(
                          bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.2)),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 64,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${dayOnly.day}',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w500,
                                    color: numberColor,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  DateFormat('EEEE', locale).format(dayOnly),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: numberColor.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              child: chipsView,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListView(List<JobDeadline> deadlines) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final today = DateFormatters.dateOnly(DateTime.now());
    final active = deadlines.where((d) => !DateFormatters.dateOnly(d.deadlineAt).isBefore(today)).toList()
      ..sort((a, b) => a.deadlineAt.compareTo(b.deadlineAt));

    final grouped = <DateTime, List<JobDeadline>>{};
    for (final d in active) {
      final date = DateFormatters.dateOnly(d.deadlineAt);
      (grouped[date] ??= []).add(d);
    }
    
    if (active.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () {
                setState(() {
                  _viewMode = _CalendarViewMode.month;
                  _focusedDay = DateTime.now();
                  _selectedDay = DateFormatters.dateOnly(DateTime.now());
                  _calendarFormat = CalendarFormat.month;
                  _expansionState = _ExpansionState.half;
                });
              },
              child: Icon(Icons.calendar_today_outlined, size: 48, color: theme.colorScheme.surfaceContainerHighest),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noSchedules,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final items = grouped[date]!;

        Color stageColor(JobDeadline job) => _stageColorFor(job, cs);

        String titleFor(JobDeadline job) {
          final prefix = job.deadlineType == DeadlineType.rolling ? '[${l10n.rollingDeadline}] ' : '';
          final company = job.companyName.isNotEmpty ? job.companyName : (job.jobTitle.isNotEmpty ? job.jobTitle : l10n.defaultScheduleTitle);
          return '$prefix$company';
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8, top: 16),
              child: Text(
                DateFormat.yMMMMEEEEd(locale).format(date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
            ),
            for (final job in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.15)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => DeadlineDetailScreen(deadlineId: job.id)),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: stageColor(job).withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: stageColor(job).withOpacity(0.5)),
                              ),
                              child: Text(
                                job.status.localizedBadgeLabel(l10n),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: cs.onSurface,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 11,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    titleFor(job),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    job.jobTitle.isNotEmpty ? job.jobTitle : l10n.noTitle,
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Builder(
                                  builder: (context) {
                                    final label = job.deadlineType == DeadlineType.rolling
                                        ? l10n.rollingDeadline
                                        : DateFormatters.dDayLabel(l10n, job.deadlineAt);
                                    final color = (label == l10n.dDayToday || label == l10n.dDayClosed) ? cs.error : cs.primary;
                                    return Text(
                                      label,
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                            fontWeight: FontWeight.w900,
                                            color: color,
                                            fontSize: 16,
                                          ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (job.isEstimated) ...[
                                      Text(
                                        job.deadlineType == DeadlineType.rolling ? '${l10n.temporary} ' : '${l10n.estimated} ',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: cs.secondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                    ],
                                    Text(
                                      DateFormatters.ymd.format(job.deadlineAt),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTableCalendar(
    DateTime selected,
    Map<DateTime, List<JobDeadline>> byDate,
    String locale,
  ) {
    final daysOfWeekHeight = 24.0;
    return TableCalendar<JobDeadline>(
      shouldFillViewport: true,
      sixWeekMonthsEnforced: false,
      locale: locale,
      startingDayOfWeek: StartingDayOfWeek.sunday,
      firstDay: DateTime(2020),
      lastDay: DateTime(2100),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      headerVisible: false,
      selectedDayPredicate: (day) => DateFormatters.dateOnly(day) == DateFormatters.dateOnly(selected),
      onDaySelected: (selectedDay, focusedDay) async {
        final dayOnly = DateFormatters.dateOnly(selectedDay);
        final isSecondTap = _selectedDay != null && DateFormatters.dateOnly(_selectedDay!) == dayOnly;
        _onFocusedDayChanged(focusedDay);
        setState(() {
          _selectedDay = dayOnly;
        });
        if (isSecondTap) {
          await _openAgenda();
        }
      },
      onDayLongPressed: (day, focusedDay) async {
        final dayOnly = DateFormatters.dateOnly(day);
        _onFocusedDayChanged(focusedDay);
        setState(() {
          _selectedDay = dayOnly;
        });
        await _openAgenda();
      },
      onPageChanged: _onFocusedDayChanged,
      eventLoader: (day) => byDate[DateFormatters.dateOnly(day)] ?? const <JobDeadline>[],
      holidayPredicate: _isHoliday,
      availableGestures: AvailableGestures.horizontalSwipe,
      daysOfWeekHeight: daysOfWeekHeight,
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: const TextStyle(fontWeight: FontWeight.w700),
        decoration: BoxDecoration(
          border: Border.symmetric(
            horizontal: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
        ),
      ),
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: true,
        cellMargin: EdgeInsets.zero,
        defaultDecoration: BoxDecoration(),
        selectedDecoration: BoxDecoration(),
        todayDecoration: BoxDecoration(),
        holidayDecoration: BoxDecoration(),
        outsideDecoration: BoxDecoration(),
        markerDecoration: BoxDecoration(),
      ),
      calendarBuilders: CalendarBuilders<JobDeadline>(
        dowBuilder: (context, day) {
          final label = DateFormat.E(locale).format(day);
          final cs = Theme.of(context).colorScheme;
          final color = day.weekday == DateTime.sunday
              ? cs.error
              : (day.weekday == DateTime.saturday ? _saturdayBlue : cs.onSurfaceVariant);
          return Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          );
        },
        markerBuilder: (context, day, events) => const SizedBox(),
        defaultBuilder: (context, day, focusedDay) => _buildDayCell(
          context,
          day,
          items: byDate[DateFormatters.dateOnly(day)] ?? const <JobDeadline>[],
          isSelected: false,
          isToday: isSameDay(day, DateTime.now()),
          isOutside: false,
          isHoliday: _isHoliday(day),
        ),
        selectedBuilder: (context, day, focusedDay) => _buildDayCell(
          context,
          day,
          items: byDate[DateFormatters.dateOnly(day)] ?? const <JobDeadline>[],
          isSelected: true,
          isToday: isSameDay(day, DateTime.now()),
          isOutside: false,
          isHoliday: _isHoliday(day),
        ),
        todayBuilder: (context, day, focusedDay) => _buildDayCell(
          context,
          day,
          items: byDate[DateFormatters.dateOnly(day)] ?? const <JobDeadline>[],
          isSelected: false,
          isToday: true,
          isOutside: false,
          isHoliday: _isHoliday(day),
        ),
        outsideBuilder: (context, day, focusedDay) => _buildDayCell(
          context,
          day,
          items: byDate[DateFormatters.dateOnly(day)] ?? const <JobDeadline>[],
          isSelected: false,
          isToday: isSameDay(day, DateTime.now()),
          isOutside: true,
          isHoliday: _isHoliday(day),
        ),
        holidayBuilder: (context, day, focusedDay) => _buildDayCell(
          context,
          day,
          items: byDate[DateFormatters.dateOnly(day)] ?? const <JobDeadline>[],
          isSelected: false,
          isToday: isSameDay(day, DateTime.now()),
          isOutside: false,
          isHoliday: true,
        ),
      ),
    );
  }

  Widget _buildAgendaView(DateTime selectedDate, List<JobDeadline> items) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();

    Color stageColor(JobDeadline job) => _stageColorFor(job, cs);

    String titleFor(JobDeadline job) {
      return job.companyName.isNotEmpty ? job.companyName : (job.jobTitle.isNotEmpty ? job.jobTitle : l10n.defaultScheduleTitle);
    }
    
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragEnd: (details) {
              _handleExpansionGesture(details.primaryVelocity!);
            },
            child: Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(
                      color: cs.onSurfaceVariant.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat.MMMMEEEEd(locale).format(selectedDate),
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20,
                                    height: 1.1,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.tabCalendar,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      FloatingActionButton.small(
                        elevation: 0,
                        highlightElevation: 0,
                        focusElevation: 0,
                        hoverElevation: 0,
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddManualScreen(
                                initialDate: _selectedDay ?? _focusedDay,
                              ),
                            ),
                          );
                        },
                        tooltip: l10n.tabAdd,
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_busy, size: 48, color: cs.surfaceContainerHighest),
                        const SizedBox(height: 16),
                        Text(
                          l10n.noSchedules,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final job = items[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.withOpacity(0.1)),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => DeadlineDetailScreen(deadlineId: job.id)),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: stageColor(job).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: stageColor(job).withOpacity(0.4)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        job.status.localizedBadgeLabel(l10n),
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: cs.onSurface,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 10,
                                            ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          titleFor(job),
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                                height: 1.2,
                                              ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          job.jobTitle.isNotEmpty ? job.jobTitle : l10n.noTitle,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontSize: 11,
                                            height: 1.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Builder(
                                        builder: (context) {
                                          final label = job.deadlineType == DeadlineType.rolling
                                              ? l10n.rollingDeadline
                                              : DateFormatters.dDayLabel(l10n, job.deadlineAt);
                                          final color = (label == l10n.dDayToday || label == l10n.dDayClosed) ? cs.error : cs.primary;
                                          return Text(
                                            label,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.w900,
                                                  color: color,
                                                  fontSize: 14,
                                                ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 1),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (job.isEstimated) ...[
                                            Text(
                                              job.deadlineType == DeadlineType.rolling ? '${l10n.temporary} ' : '${l10n.estimated} ',
                                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                    color: cs.secondary,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 10,
                                                  ),
                                            ),
                                          ],
                                          Text(
                                            DateFormatters.ymd.format(job.deadlineAt),
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: cs.onSurfaceVariant,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final deadlines = appState.deadlines;

    final byDate = <DateTime, List<JobDeadline>>{};
    for (final d in deadlines) {
      final key = DateFormatters.dateOnly(d.deadlineAt);
      (byDate[key] ??= <JobDeadline>[]).add(d);
    }

    final selected = _selectedDay ?? DateFormatters.dateOnly(DateTime.now());
    final selectedItems = (byDate[DateFormatters.dateOnly(selected)] ?? <JobDeadline>[])
      ..sort((a, b) => a.deadlineAt.compareTo(b.deadlineAt));

    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    String headerTitle;
    if (locale.startsWith('ko')) {
      headerTitle = DateFormat('yy${l10n.year} M${l10n.month}', locale).format(_focusedDay);
    } else {
      headerTitle = DateFormat.yMMMM(locale).format(_focusedDay);
    }

    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
          child: Stack(
            children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
                  child: SizedBox(
                    height: 32,
                    child: Row(
                      children: [
                        // Left: Profile & Title
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: cs.primary.withOpacity(0.1),
                                foregroundColor: cs.primary,
                                child: const Icon(Icons.person, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    l10n.tabCalendar,
                                    style: theme.textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 22,
                                          letterSpacing: -0.5,
                                        ),
                                    maxLines: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Center: Year/Month Selector
                        InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            final picked = await showDialog<DateTime>(
                              context: context,
                              builder: (context) {
                                DateTime tempDate = _focusedDay;
                                return AlertDialog(
                                  title: Text(l10n.selectDate),
                                  content: StatefulBuilder(
                                    builder: (context, setDialogState) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              // Year Selection
                                              DropdownButton<int>(
                                                value: tempDate.year,
                                                items: List.generate(81, (i) => 2020 + i)
                                                    .map((y) => DropdownMenuItem(value: y, child: Text('$y${l10n.year}')))
                                                    .toList(),
                                                onChanged: (y) {
                                                  if (y != null) {
                                                    setDialogState(() => tempDate = DateTime(y, tempDate.month));
                                                  }
                                                },
                                              ),
                                              // Month Selection
                                              DropdownButton<int>(
                                                value: tempDate.month,
                                                items: List.generate(12, (i) => i + 1)
                                                    .map((m) => DropdownMenuItem(value: m, child: Text('$m${l10n.month}')))
                                                    .toList(),
                                                onChanged: (m) {
                                                  if (m != null) {
                                                    setDialogState(() => tempDate = DateTime(tempDate.year, m));
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(l10n.cancel),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, tempDate),
                                      child: Text(l10n.ok),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (picked == null || !mounted) return;
                            _onFocusedDayChanged(DateTime(picked.year, picked.month, 1));
                            setState(() {
                              _selectedDay = DateFormatters.dateOnly(picked);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  headerTitle,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: cs.onSurface,
                                        height: 1.0,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const Icon(Icons.arrow_drop_down, size: 24),
                              ],
                            ),
                          ),
                        ),

                        // Right: Icons
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: () {
                                  final now = DateTime.now();
                                  _onFocusedDayChanged(now);
                                  setState(() {
                                    _selectedDay = DateFormatters.dateOnly(now);
                                    // 오늘로 이동할 때는 기본 달력 보기(월간)로 전환
                                    _viewMode = _CalendarViewMode.month;
                                  });
                                },
                                icon: const Icon(Icons.today_outlined, size: 24),
                                tooltip: l10n.today,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _showStageColorSettings(context),
                                icon: const Icon(Icons.color_lens_outlined, size: 24),
                                tooltip: l10n.noteReviewStatus,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _toggleViewMode,
                                icon: Icon(
                                  _viewMode == _CalendarViewMode.month
                                      ? Icons.calendar_view_month
                                      : (_viewMode == _CalendarViewMode.week
                                          ? Icons.calendar_view_day
                                          : Icons.view_list),
                                  size: 24,
                                ),
                                tooltip: l10n.tabList,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                style: IconButton.styleFrom(
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const AdPlaceholder(),

                Expanded(
                  child: Column(
                    children: [
                      if (_viewMode == _CalendarViewMode.list)
                        Expanded(child: _buildListView(deadlines))
                      else if (_viewMode == _CalendarViewMode.week)
                        Expanded(flex: 10, child: _buildWeekView(byDate))
                      else
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final totalHeight = constraints.maxHeight;
                              double agendaTop;
                              double calendarHeight;
                              
                              switch (_expansionState) {
                                case _ExpansionState.calendarFull:
                                  agendaTop = totalHeight;
                                  calendarHeight = totalHeight; // 1단계: 달력이 전체를 채움
                                  break;
                                case _ExpansionState.half:
                                  agendaTop = totalHeight * 0.55;
                                  calendarHeight = agendaTop; // 2단계: 리스트 헤더 바로 위까지 달력 표시
                                  break;
                                case _ExpansionState.agendaFull:
                                  agendaTop = totalHeight * 0.1;
                                  calendarHeight = totalHeight * 0.55; // 3단계: 리스트가 넓어질 때도 달력 크기 유지 (가려짐)
                                  break;
                                default:
                                  agendaTop = totalHeight * 0.55;
                                  calendarHeight = agendaTop;
                              }

                              return Stack(
                                children: [
                                  // Calendar Layer (Animated height and sync with agenda)
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 300),
                                    curve: Curves.easeOutCubic,
                                    top: 0,
                                    left: 0,
                                    right: 0,
                                    height: calendarHeight,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onVerticalDragEnd: (details) => _handleExpansionGesture(details.primaryVelocity!),
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(0, 1, 0, 4),
                                        child: _buildTableCalendar(selected, byDate, locale),
                                      ),
                                    ),
                                  ),
                                  // Agenda Layer (Slides over calendar)
                                  if (_expansionState != _ExpansionState.calendarFull)
                                    AnimatedPositioned(
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOutCubic,
                                      top: agendaTop,
                                      left: 0,
                                      right: 0,
                                      bottom: 0,
                                      child: _buildAgendaView(selected, selectedItems),
                                    ),
                                ],
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Set<String> _parseHolidayJson(String jsonBody) {
  try {
    final decoded = jsonDecode(jsonBody);
    if (decoded is! List) return {};
    final next = <String>{};
    for (final item in decoded) {
      if (item is! Map) continue;
      final date = item['date'];
      if (date is String && date.length == 10) {
        next.add(date);
      }
    }
    return next;
  } catch (_) {
    return {};
  }
}
