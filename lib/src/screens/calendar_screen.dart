import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:table_calendar/table_calendar.dart';

import '../models/job_deadline.dart';
import '../models/job_status.dart';
import '../state/app_state_scope.dart';
import '../ui/date_formatters.dart';
import '../widgets/ad_placeholder.dart';
import 'add_from_share_screen.dart';
import 'deadline_detail_screen.dart';

enum _CalendarViewMode { month, week, list }

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  int _handledSavedRevision = 0;
  static const _saturdayBlue = Color(0xFF2563EB);
  static const _docPink = Color(0xFFFFC1DC);
  static const _aptOrange = Color(0xFFFFD59E);
  static const _interviewGreen = Color(0xFFB7F0C0);
  final Map<int, Set<String>> _holidayFetchedByYear = {};
  final Set<int> _holidayFetchInFlight = {};
  
  _CalendarViewMode _viewMode = _CalendarViewMode.month;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  StreamSubscription? _resetSub;
  bool _isCalendarExpanded = true;

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
    _resetSub = AppStateScope.of(context).onCalendarReset.listen((_) {
      if (!mounted) return;
      setState(() {
        _focusedDay = DateTime.now();
        _selectedDay = DateFormatters.dateOnly(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _resetSub?.cancel();
    super.dispose();
  }

  static const _holidayByYear = <int, Set<String>>{
    2026: {
      '2026-01-01',
      '2026-02-16',
      '2026-02-17',
      '2026-02-18',
      '2026-03-01',
      '2026-03-02',
      '2026-05-05',
      '2026-05-24',
      '2026-05-25',
      '2026-06-03',
      '2026-06-06',
      '2026-08-15',
      '2026-08-17',
      '2026-09-24',
      '2026-09-25',
      '2026-09-26',
      '2026-10-03',
      '2026-10-05',
      '2026-10-09',
      '2026-12-25',
    },
    2027: {
      '2027-01-01',
      '2027-02-06',
      '2027-02-07',
      '2027-02-08',
      '2027-02-09',
      '2027-03-01',
      '2027-05-05',
      '2027-05-13',
      '2027-06-06',
      '2027-06-07',
      '2027-08-15',
      '2027-08-16',
      '2027-09-14',
      '2027-09-15',
      '2027-09-16',
      '2027-10-03',
      '2027-10-04',
      '2027-10-09',
      '2027-10-11',
      '2027-12-25',
      '2027-12-27',
    },
    2028: {
      '2028-01-01',
      '2028-01-26',
      '2028-01-27',
      '2028-03-01',
      '2028-05-05',
      '2028-06-06',
      '2028-08-15',
      '2028-10-02',
      '2028-10-03',
      '2028-10-04',
      '2028-10-09',
      '2028-12-25',
    },
  };

  static String _ymdKey(DateTime day) => '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

  static bool _isFixedHoliday(DateTime day) {
    final m = day.month;
    final d = day.day;
    if (m == 1 && d == 1) return true;
    if (m == 3 && d == 1) return true;
    if (m == 5 && d == 5) return true;
    if (m == 6 && d == 6) return true;
    if (m == 8 && d == 15) return true;
    if (m == 10 && d == 3) return true;
    if (m == 10 && d == 9) return true;
    if (m == 12 && d == 25) return true;
    return false;
  }

  bool _isHoliday(DateTime day) {
    final key = _ymdKey(DateFormatters.dateOnly(day));
    final fetched = _holidayFetchedByYear[day.year];
    if (fetched != null && fetched.contains(key)) return true;
    final yearSet = _holidayByYear[day.year];
    if (yearSet != null && yearSet.contains(key)) return true;
    return _isFixedHoliday(day);
  }

  Color _stageColorFor(JobDeadline job, ColorScheme cs) {
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final baseTextColor = _dayTextColor(context, day) ?? cs.onSurface;
    final numberColor = isOutside ? baseTextColor.withValues(alpha: 0.35) : baseTextColor;
    final selectedBg = cs.surfaceContainerHigh;

    final shown = items.take(3).toList(growable: false);
    final remaining = items.length - shown.length;

    Widget dayNumber() {
      return Text(
        '${day.day}',
        style: theme.textTheme.labelMedium?.copyWith(
          color: numberColor,
          fontWeight: isToday ? FontWeight.w900 : FontWeight.w600,
        ),
      );
    }

    Color stageColor(JobDeadline job) => _stageColorFor(job, cs);

    String chipTitle(JobDeadline job) {
      return job.companyName.isNotEmpty ? job.companyName : (job.jobTitle.isNotEmpty ? job.jobTitle : '일정');
    }

    return SizedBox.expand(
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOutCubic,
        scale: isSelected ? 1.01 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(2, 2, 2, 1),
          decoration: BoxDecoration(
            color: isSelected ? selectedBg : Colors.transparent,
            border: const Border(
              top: BorderSide(
                color: Color(0xFFE0E0E0), // Light silver
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              dayNumber(),
              const SizedBox(height: 2),
              for (final job in shown)
                Padding(
                  padding: const EdgeInsets.only(bottom: 1),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: stageColor(job),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      chipTitle(job),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.left,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 9.5,
                        height: 1.1,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              if (remaining > 0)
                Text(
                  '+$remaining',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontSize: 9,
                  ),
                ),
            ],
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
      final uri = Uri.parse('https://date.nager.at/api/v3/PublicHolidays/$year/KR');
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

  Future<void> _openAgenda() async {
    if (!mounted) return;
    if (_viewMode != _CalendarViewMode.month) return;
    setState(() => _isCalendarExpanded = false);
  }

  void _toggleViewMode() {
    setState(() {
      if (_viewMode == _CalendarViewMode.month) {
        _viewMode = _CalendarViewMode.week;
        _calendarFormat = CalendarFormat.week;
        _isCalendarExpanded = true;
      } else if (_viewMode == _CalendarViewMode.week) {
        _viewMode = _CalendarViewMode.list;
        _isCalendarExpanded = true;
      } else {
        _viewMode = _CalendarViewMode.month;
        _calendarFormat = CalendarFormat.month;
      }
    });
  }

  static DateTime _weekStart(DateTime day) {
    final d = DateFormatters.dateOnly(day);
    return d.subtract(Duration(days: d.weekday % 7));
  }

  Widget _buildWeekView(Map<DateTime, List<JobDeadline>> byDate) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
      return job.companyName.isNotEmpty ? job.companyName : (job.jobTitle.isNotEmpty ? job.jobTitle : '일정');
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
          job.status.badgeLabel,
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
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.45)),
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final rowHeight = constraints.maxHeight / 7.0;
          final maxChips = rowHeight >= 78 ? 2 : 1;

          return Column(
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
                      final numberColor = isOutside ? baseTextColor.withValues(alpha: 0.35) : baseTextColor;

                      final items = List<JobDeadline>.from(byDate[dayOnly] ?? const <JobDeadline>[])
                        ..sort((a, b) => a.deadlineAt.compareTo(b.deadlineAt));
                      final shown = items.take(maxChips).toList(growable: false);
                      final remaining = items.length - shown.length;

                      final right = shown.isEmpty
                          ? const SizedBox.shrink()
                          : (maxChips == 1
                              ? Row(
                                  children: [
                                    Expanded(child: chip(shown[0])),
                                    if (remaining > 0) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        '+$remaining',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < shown.length; i++) ...[
                                      chip(shown[i]),
                                      if (i != shown.length - 1) const SizedBox(height: 6),
                                    ],
                                    if (remaining > 0) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '+$remaining',
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: cs.onSurfaceVariant,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ],
                                ));

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
                              bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                                      DateFormat('EEEE', 'ko_KR').format(dayOnly),
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        color: numberColor.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: right),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListView(List<JobDeadline> deadlines) {
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
        child: Text(
          '등록된 일정이 없습니다.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 20),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final date = grouped.keys.elementAt(index);
        final items = grouped[date]!;
        final cs = Theme.of(context).colorScheme;
        final theme = Theme.of(context);

        Color stageColor(JobDeadline job) => _stageColorFor(job, cs);

        String titleFor(JobDeadline job) {
          return job.companyName.isNotEmpty ? job.companyName : (job.jobTitle.isNotEmpty ? job.jobTitle : '일정');
        }

        Color badgeFgFor(JobDeadline job) {
          if (job.status == JobStatus.closed) return cs.onSurfaceVariant;
          return cs.onSurface;
        }

        Widget badge(JobDeadline job) {
          final bg = job.status == JobStatus.closed ? cs.surfaceContainerHighest : stageColor(job);
          return Container(
            width: 42,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              job.status.badgeLabel,
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: theme.textTheme.labelSmall?.copyWith(
                color: badgeFgFor(job),
                fontWeight: FontWeight.w900,
                fontSize: 11,
                height: 1.0,
                letterSpacing: -0.2,
              ),
            ),
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: cs.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(date),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            for (final job in items)
              ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: badge(job),
                title: Text(titleFor(job)),
                subtitle: job.companyName.isNotEmpty && job.jobTitle.isNotEmpty ? Text(job.jobTitle) : null,
                onTap: () async {
                   await Navigator.of(context).push(
                     MaterialPageRoute(builder: (_) => DeadlineDetailScreen(deadlineId: job.id)),
                   );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildAgendaView(DateTime selectedDate, List<JobDeadline> items) {
    final cs = Theme.of(context).colorScheme;

    Color stageColor(JobDeadline job) => _stageColorFor(job, cs);

    Color badgeFgFor(JobDeadline job) {
      if (job.status == JobStatus.closed) return cs.onSurfaceVariant;
      return cs.onSurface;
    }

    String titleFor(JobDeadline job) {
      return job.companyName.isNotEmpty ? job.companyName : '회사명 없음';
    }
    
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    DateFormat('M월 d일 EEEE', 'ko_KR').format(selectedDate),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton.filled(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddFromShareScreen(sharedText: null)),
                    );
                  },
                  icon: const Icon(Icons.add),
                  tooltip: '추가',
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      '등록된 일정이 없습니다.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final job = items[index];
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            visualDensity: VisualDensity.compact,
                            minLeadingWidth: 10,
                            horizontalTitleGap: 10,
                            minVerticalPadding: 0,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            leading: Container(
                              width: 38,
                              height: 22,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: stageColor(job),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                job.status.badgeLabel,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: badgeFgFor(job),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 10.5,
                                    ),
                              ),
                            ),
                            title: Text(
                              titleFor(job),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                            subtitle: Text(
                              job.jobTitle.isNotEmpty ? job.jobTitle : '제목 없음',
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => DeadlineDetailScreen(deadlineId: job.id)),
                              );
                            },
                          ),
                          Divider(height: 1, thickness: 1, color: cs.outlineVariant.withValues(alpha: 0.2)),
                        ],
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
    final savedRevision = appState.lastSavedRevision;
    final savedAt = appState.lastSavedDeadlineAt;
    if (savedAt != null && savedRevision != _handledSavedRevision) {
      _handledSavedRevision = savedRevision;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final dayOnly = DateFormatters.dateOnly(savedAt);
        _onFocusedDayChanged(dayOnly);
        setState(() {
          _selectedDay = dayOnly;
        });
      });
    }

    final byDate = <DateTime, List<JobDeadline>>{};
    for (final d in deadlines) {
      final key = DateFormatters.dateOnly(d.deadlineAt);
      (byDate[key] ??= <JobDeadline>[]).add(d);
    }

    final selected = _selectedDay ?? DateFormatters.dateOnly(DateTime.now());
    final selectedItems = (byDate[DateFormatters.dateOnly(selected)] ?? <JobDeadline>[])
      ..sort((a, b) => a.deadlineAt.compareTo(b.deadlineAt));

    final headerTitle = '${_focusedDay.year}년 ${_focusedDay.month}월';
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.primaryContainer,
                        foregroundColor: cs.onPrimaryContainer,
                        child: const Icon(Icons.person, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _focusedDay,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked == null || !mounted) return;
                            _onFocusedDayChanged(DateTime(picked.year, picked.month, 1));
                            setState(() {
                              _selectedDay = DateFormatters.dateOnly(picked);
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      headerTitle,
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900, fontSize: 19),
                                    ),
                                    const Icon(Icons.arrow_drop_down),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.star_border),
                        tooltip: '즐겨찾기',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 14),
                      IconButton(
                        onPressed: _toggleViewMode,
                        icon: Icon(
                          _viewMode == _CalendarViewMode.month
                              ? Icons.calendar_view_month
                              : (_viewMode == _CalendarViewMode.week
                                  ? Icons.calendar_view_week
                                  : Icons.view_list),
                        ),
                        tooltip: '보기 전환',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),

                const AdPlaceholder(),

                Expanded(
                  child: GestureDetector(
                    onVerticalDragEnd: (details) {
                      if (_viewMode != _CalendarViewMode.month) return;
                      if (details.primaryVelocity! > 300) {
                        if (!_isCalendarExpanded) {
                          setState(() => _isCalendarExpanded = true);
                        }
                      } else if (details.primaryVelocity! < -300) {
                        if (_isCalendarExpanded) {
                          setState(() => _isCalendarExpanded = false);
                        }
                      }
                    },
                    child: Column(
                      children: [
                        if (_viewMode == _CalendarViewMode.list)
                          Expanded(child: _buildListView(deadlines))
                        else if (_viewMode == _CalendarViewMode.week)
                          Expanded(flex: 10, child: _buildWeekView(byDate))
                        else
                          Expanded(
                            flex: _isCalendarExpanded ? 10 : 6,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                            final daysOfWeekHeight = 24.0;
                            // sixWeekMonthsEnforced=false 일 때는 해당 월이 4주, 5주, 6주 중 하나일 수 있음.
                            // 하지만 shouldFillViewport=true일 경우 TableCalendar가 높이를 꽉 채우려고 하므로,
                            // rowHeight를 고정값으로 주거나, 동적으로 계산해야 함.
                            // 여기서는 간단히 6주 기준으로 계산하되, clamp를 통해 최소 높이를 보장.
                            // 만약 5주만 표시되는 달이라면 각 셀의 높이가 더 늘어나서 빈 공간을 채우게 됨 (shouldFillViewport 덕분).
                            // 하지만 사용자는 "높이가 부족하다"고 했으므로, 
                            // 6주 강제 표시를 끄고(false), 
                            // shouldFillViewport가 true이므로 TableCalendar가 알아서 남은 공간을 N등분함.
                            // 따라서 rowHeight 속성을 아예 제거하거나 null로 주면 TableCalendar가 자동 계산함(shouldFillViewport: true일 때).
                            // 단, 라이브러리 버전에 따라 동작이 다를 수 있으니, 
                            // 여기서는 rowHeight 계산식을 유지하되, rows 변수를 동적으로 할 수 없으므로(LayoutBuilder 시점엔 몇 주인지 모름),
                            // 일단 rowHeight 속성을 제거하여 자동 계산에 맡겨봄.
                            
                            return TableCalendar<JobDeadline>(
                              shouldFillViewport: _calendarFormat == CalendarFormat.month,
                              sixWeekMonthsEnforced: false,
                              locale: 'ko_KR',
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
                                horizontal: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                              ),
                            ),
                          ),
                              calendarStyle: const CalendarStyle(
                                outsideDaysVisible: true,
                                cellMargin: EdgeInsets.zero,
                              ),
                              calendarBuilders: CalendarBuilders<JobDeadline>(
                                markerBuilder: (context, day, events) => const SizedBox(),
                                dowBuilder: (context, day) {
                                  const labels = ['일', '월', '화', '수', '목', '금', '토'];
                                  final label = labels[day.weekday % 7];
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
                          },
                        ),
                      ),
                    ),
                    
                    if (!_isCalendarExpanded && _viewMode == _CalendarViewMode.month)
                      Expanded(
                        flex: 4,
                        child: _buildAgendaView(selected, selectedItems),
                      ),
                ],
              ),
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
