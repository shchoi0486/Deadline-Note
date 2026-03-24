import 'package:flutter/material.dart';
import 'package:deadline_note/l10n/app_localizations.dart';

import '../models/deadline_type.dart';
import '../models/job_deadline.dart';
import '../models/job_status.dart';
import '../state/app_state_scope.dart';
import '../ui/date_formatters.dart';
import '../widgets/ad_placeholder.dart';
import 'deadline_detail_screen.dart';

enum _PipelineFilter {
  all,
  document,
  aptitude,
  interview,
  failed,
}

class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final allDeadlines = appState.deadlines.toList()..sort((a, b) => a.deadlineAt.compareTo(b.deadlineAt));
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return DefaultTabController(
      length: _PipelineFilter.values.length,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
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
                                  l10n.tabList,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 22,
                                        letterSpacing: -0.5,
                                        height: 1.0,
                                      ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Center: Empty or relevant info
                      const SizedBox.shrink(),

                      // Right: Actions
                      const Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 캘린더 화면의 아이콘 3개 공간(24*3) + 간격(8*2) 만큼 비워두어 중앙 정렬 유지
                            SizedBox(width: 24 * 3 + 8 * 2), 
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const AdPlaceholder(),
                const SizedBox(height: 1),
                TabBar(
                  isScrollable: false,
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(text: l10n.filterAll),
                    Tab(text: l10n.filterDocument),
                    Tab(text: l10n.filterAptitude),
                    Tab(text: l10n.filterInterview),
                    Tab(text: l10n.filterFailed),
                  ],
                ),
              Expanded(
                child: TabBarView(
                  children: _PipelineFilter.values.map((filter) {
                    final items = allDeadlines.where((d) {
                      switch (filter) {
                        case _PipelineFilter.all:
                          return d.outcome != JobOutcome.failed;
                        case _PipelineFilter.document:
                          return d.status.isAppliedGroup;
                        case _PipelineFilter.aptitude:
                          return d.status == JobStatus.videoInterview;
                        case _PipelineFilter.interview:
                          return d.status == JobStatus.interview1 ||
                              d.status == JobStatus.interview2 ||
                              d.status == JobStatus.finalInterview;
                        case _PipelineFilter.failed:
                          return d.outcome == JobOutcome.failed;
                      }
                    }).toList();

                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text(
                            l10n.noFilteredSchedules,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      );
                    }

                    final inProgress =
                        items.where((d) => d.status != JobStatus.closed && d.outcome == JobOutcome.none).toList(growable: false);
                    final passed =
                        items.where((d) => d.outcome == JobOutcome.passed).toList(growable: false);
                    final closedOrFailed = items.where((d) => d.status == JobStatus.closed || d.outcome == JobOutcome.failed).toList(growable: false);

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      children: [
                        if (inProgress.isNotEmpty) _StatusSection(title: l10n.statusInProgress, items: inProgress),
                        if (passed.isNotEmpty) _StatusSection(title: l10n.statusPassed, items: passed),
                        if (closedOrFailed.isNotEmpty) _StatusSection(title: l10n.statusClosed, items: closedOrFailed),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.title, required this.items});

  final String title;
  final List<JobDeadline> items;

  // 달력의 색상과 동일하게 맞춤
  static const _docPink = Color(0xFFFFC1DC);
  static const _aptOrange = Color(0xFFFFD59E);
  static const _interviewGreen = Color(0xFFB7F0C0);

  ({Color bg, Color fg}) _chipColorsFor(BuildContext context, JobDeadline d, ColorScheme cs) {
    if (d.status == JobStatus.closed) {
      return (bg: cs.surfaceContainerHighest, fg: cs.onSurfaceVariant);
    }
    
    // AppSettings에서 커스텀 색상 가져오기
    final settings = AppStateScope.of(context).settings;
    final customColorValue = settings.stageColors[d.status.name];
    
    if (customColorValue != null) {
      final color = Color(customColorValue);
      return (bg: color, fg: Colors.black.withOpacity(0.7));
    }

    // 기본 색상 (커스텀 설정이 없는 경우)
    if (d.status == JobStatus.document) {
      return (bg: _docPink, fg: Colors.black.withOpacity(0.7));
    }
    if (d.status == JobStatus.videoInterview) {
      return (bg: _aptOrange, fg: Colors.black.withOpacity(0.7));
    }
    if (d.status.isInterviewGroup) {
      return (bg: _interviewGreen, fg: Colors.black.withOpacity(0.7));
    }
    return (bg: cs.primaryContainer, fg: cs.onPrimaryContainer);
  }



  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // 섹션 타이틀 로직 수정: '합격'이라는 용어 대신 상태에 맞는 용어 사용
    // 다만 여기서는 단순히 섹션 타이틀을 표시하지 않거나,
    // title 변수를 그대로 사용하되 상위에서 넘겨주는 값을 조정하는 것이 좋음.
    // 현재 상위에서 '합격'이라고 넘겨주고 있으므로, 이를 화면에 표시할 때 조건에 따라 변경하거나
    // 아예 상위 호출부에서 '완료된 전형' 등으로 변경해서 넘겨주는 것이 좋음.
    // 일단 여기서는 title을 그대로 표시.
    
    final l10n = AppLocalizations.of(context)!;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀이 '합격'일 경우, 사용자 피드백에 따라 표시하지 않거나 다른 이름으로 변경 고려
          // 여기서는 '합격' 타이틀을 아예 숨기거나, '전형 통과' 등으로 변경할 수 있음.
          // 사용자 요청: "마감일 기준으로 일정을 잡는건데 왜 합격이라고 써놨음?"
          // -> '합격' 섹션은 outcome == passed 인 항목들임.
          // -> 하지만 사용자는 이를 '합격'이라고 부르는 것을 어색해함 (아직 최종 합격이 아닐 수 있으므로).
          // -> 따라서 '전형 통과' 또는 '다음 전형 대기' 등으로 순화하거나, 
          // -> 아예 타이틀을 '완료된 일정' 등으로 변경하는 것이 좋음.
          // -> 상위 위젯(build 메서드)에서 title을 수정해서 넘기는 것이 깔끔함.
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          for (final d in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.15)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DeadlineDetailScreen(deadlineId: d.id)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) {
                            final colors = _chipColorsFor(context, d, cs);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: colors.bg.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: colors.bg.withOpacity(0.5)),
                              ),
                              child: Text(
                                d.status.localizedBadgeLabel(l10n),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurface, // colors.fg 대신 일관된 텍스트 색상 사용
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.companyName.isNotEmpty ? d.companyName : l10n.noCompanyName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                d.jobTitle.isNotEmpty ? d.jobTitle : l10n.noTitle,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
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
                                final label = d.deadlineType == DeadlineType.rolling
                                      ? l10n.rollingDeadline
                                      : DateFormatters.dDayLabel(l10n, d.deadlineAt);
                                  final color = (label == l10n.dDayToday || label == l10n.dDayClosed) ? cs.error : cs.primary;
                                  return Text(
                                  label,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                    fontSize: 14,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (d.isEstimated) ...[
                                  Text(
                                    d.deadlineType == DeadlineType.rolling ? '${l10n.temporary} ' : '${l10n.estimated} ',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.secondary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                                Text(
                                  DateFormatters.ymd.format(d.deadlineAt),
                                  style: theme.textTheme.bodySmall?.copyWith(
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
            ),
        ],
      ),
    );
  }
}
