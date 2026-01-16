import 'package:flutter/material.dart';

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

    return DefaultTabController(
      length: _PipelineFilter.values.length,
      child: Scaffold(
        body: SafeArea(
          child: Column(
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
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '현황(Pipeline)',
                                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 19,
                                        ),
                                  ),
                                  const Icon(Icons.arrow_drop_down, color: Colors.transparent),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.star_border, color: Colors.transparent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 14),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.view_list, color: Colors.transparent),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const AdPlaceholder(),
              const SizedBox(height: 6),
              TabBar(
                isScrollable: false,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
                tabs: const [
                  Tab(text: '전체'),
                  Tab(text: '서류'),
                  Tab(text: '인적성'),
                  Tab(text: '면접'),
                  Tab(text: '불합격'),
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
                          return d.status.isInterviewGroup;
                        case _PipelineFilter.failed:
                          return d.outcome == JobOutcome.failed;
                      }
                    }).toList();

                    if (items.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Text(
                            '조건에 맞는 일정이 없어요.',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ),
                      );
                    }

                    final inProgress =
                        items.where((d) => d.status != JobStatus.closed && d.outcome == JobOutcome.none).toList(growable: false);
                    final passed = items.where((d) => d.outcome == JobOutcome.passed).toList(growable: false);
                    final closedOrFailed = items.where((d) => d.status == JobStatus.closed || d.outcome == JobOutcome.failed).toList(growable: false);

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                      children: [
                        if (inProgress.isNotEmpty) _StatusSection(title: '진행 중', items: inProgress),
                        if (passed.isNotEmpty) _StatusSection(title: '전형 통과', items: passed),
                        if (closedOrFailed.isNotEmpty) _StatusSection(title: '마감/불합격', items: closedOrFailed),
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

  ({Color bg, Color fg}) _chipColorsFor(JobDeadline d, ColorScheme cs) {
    if (d.status == JobStatus.closed) {
      return (bg: cs.surfaceContainerHighest, fg: cs.onSurfaceVariant);
    }
    // 합격/불합격 여부와 상관없이 현재 전형 단계에 맞는 색상을 반환하도록 수정
    // (합격했더라도 '최종면접' 단계라면 최종면접 색상 유지 등)
    if (d.status == JobStatus.document) {
      // 서류(document)는 달력과 동일한 분홍색 계열 사용
      return (bg: _docPink, fg: Colors.black.withValues(alpha: 0.7));
    }
    if (d.status == JobStatus.videoInterview) {
      // 인적성(videoInterview)은 달력과 동일한 주황색 계열 사용
      return (bg: _aptOrange, fg: Colors.black.withValues(alpha: 0.7));
    }
    if (d.status.isInterviewGroup) {
      // 면접 그룹(1차, 2차, 최종)은 달력과 동일한 초록색 계열 사용
      return (bg: _interviewGreen, fg: Colors.black.withValues(alpha: 0.7));
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
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          for (final d in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                elevation: 0,
                color: cs.surfaceContainerLow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => DeadlineDetailScreen(deadlineId: d.id)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) {
                            final colors = _chipColorsFor(d, cs);
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: colors.bg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                d.status.badgeLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.fg,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.companyName.isNotEmpty ? d.companyName : '회사명 없음',
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                                maxLines: 1,
                                overflow: TextOverflow.clip,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                d.jobTitle.isNotEmpty ? d.jobTitle : '제목 없음',
                                style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
                                final label = DateFormatters.dDayLabel(d.deadlineAt);
                                final color = (label == 'D-DAY' || label == '마감') ? cs.error : cs.primary;
                                return Text(
                                  label,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: color,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormatters.ymd.format(d.deadlineAt),
                              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
