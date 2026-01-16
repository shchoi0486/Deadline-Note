import 'dart:math';

import 'package:flutter/material.dart';

import '../models/job_deadline.dart';
import '../models/job_site.dart';
import '../models/job_status.dart';
import '../ui/date_formatters.dart';

class DeadlineEditorForm extends StatefulWidget {
  const DeadlineEditorForm({
    required this.initial,
    required this.onSubmit,
    required this.submitLabel,
    this.warnings = const <String>[],
    this.allowDelete = false,
    this.onDelete,
    super.key,
  });

  final JobDeadline initial;
  final Future<void> Function(JobDeadline next) onSubmit;
  final String submitLabel;
  final List<String> warnings;
  final bool allowDelete;
  final Future<void> Function()? onDelete;

  @override
  State<DeadlineEditorForm> createState() => _DeadlineEditorFormState();
}

class _DeadlineEditorFormState extends State<DeadlineEditorForm> {
  final _rng = Random();
  late final TextEditingController _companyController;
  late final TextEditingController _titleController;
  late final TextEditingController _linkController;
  late final TextEditingController _salaryController;
  late final TextEditingController _memoController;

  late DateTime _deadlineAt;
  JobStatus _status = JobStatus.document;
  JobOutcome _outcome = JobOutcome.none;
  bool _notificationsEnabled = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController(text: widget.initial.companyName);
    _titleController = TextEditingController(text: widget.initial.jobTitle);
    _linkController = TextEditingController(text: widget.initial.linkUrl);
    _salaryController = TextEditingController(text: widget.initial.salary);
    _memoController = TextEditingController(text: widget.initial.memo);
    _deadlineAt = widget.initial.deadlineAt;
    _status = widget.initial.status.isPipelineStage ? widget.initial.status : JobStatus.document;
    _outcome = widget.initial.outcome;
    _notificationsEnabled = widget.initial.notificationsEnabled;
  }

  @override
  void dispose() {
    _companyController.dispose();
    _titleController.dispose();
    _linkController.dispose();
    _salaryController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  String _randomId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    return '$now-${_rng.nextInt(9999).toString().padLeft(4, '0')}';
  }

  DateTime _atEndOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59);

  Future<bool> _saveCurrentSilently() async {
    if (_submitting) return false;
    final company = _companyController.text.trim();
    if (company.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회사명은 필수예요.')));
      return false;
    }

    final title = _titleController.text.trim();
    final link = _linkController.text.trim();

    setState(() => _submitting = true);
    try {
      final next = widget.initial.copyWith(
        companyName: company,
        jobTitle: title,
        linkUrl: link,
        salary: _salaryController.text.trim(),
        deadlineAt: _deadlineAt,
        status: _status,
        outcome: _outcome,
        notificationsEnabled: _notificationsEnabled,
        memo: _memoController.text.trim(),
      );
      await widget.onSubmit(next);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했어요: $e')));
      }
      return false;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickDeadline() async {
    final initialDate = DateFormatters.dateOnly(_deadlineAt);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() => _deadlineAt = _atEndOfDay(picked));
  }

  Future<void> _openNextStepSheet() async {
    final pipeline = kPipelineStageOptions;
    final currentIndex = pipeline.indexOf(_status);
    final nextStageOptions = currentIndex >= 0
        ? pipeline.skip(currentIndex + 1).toList(growable: false)
        : pipeline.where((s) => s != JobStatus.document).toList(growable: false);
    if (nextStageOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('다음 전형이 없어요.')));
      return;
    }

    var nextStage = nextStageOptions.first;
    final base = DateFormatters.dateOnly(_deadlineAt).add(const Duration(days: 7));
    var nextDate = _atEndOfDay(base);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final paddingBottom = MediaQuery.of(context).viewInsets.bottom;

        Future<void> pickNextDate(void Function(void Function()) setModalState) async {
          final picked = await showDatePicker(
            context: context,
            initialDate: DateFormatters.dateOnly(nextDate),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked == null) return;
          setModalState(() => nextDate = _atEndOfDay(picked));
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + paddingBottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('다음 일정 추가', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 44,
                      child: DropdownMenu<JobStatus>(
                        width: double.infinity,
                        initialSelection: nextStage,
                        onSelected: (v) {
                          if (v == null) return;
                          setModalState(() => nextStage = v);
                        },
                        textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15.0),
                        dropdownMenuEntries: nextStageOptions
                            .map(
                              (s) => DropdownMenuEntry<JobStatus>(
                                value: s,
                                label: s.label,
                                style: ButtonStyle(
                                  textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 15)),
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        label: const Text('전형', style: TextStyle(fontSize: 14.0)),
                        inputDecorationTheme: InputDecorationTheme(
                          isDense: true,
                          filled: false,
                          constraints: const BoxConstraints.tightFor(height: 44),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                          ),
                          labelStyle: TextStyle(fontSize: 14.0, color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 44,
                      child: InkWell(
                        onTap: () => pickNextDate(setModalState),
                        borderRadius: BorderRadius.circular(8),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: '일정일',
                            isDense: true,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                            ),
                            labelStyle: TextStyle(fontSize: 14.0, color: cs.onSurfaceVariant),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  DateFormatters.ymd.format(nextDate),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15.0),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.event, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('취소'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submitting
                                ? null
                                : () async {
                                    final company = _companyController.text.trim();
                                    if (company.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회사명은 필수예요.')));
                                      return;
                                    }

                                    final next = JobDeadline(
                                      id: _randomId(),
                                      companyName: company,
                                      jobTitle: _titleController.text.trim(),
                                      deadlineAt: nextDate,
                                      linkUrl: _linkController.text.trim(),
                                      site: widget.initial.site,
                                      salary: _salaryController.text.trim(),
                                      status: nextStage,
                                      outcome: JobOutcome.none,
                                      notificationsEnabled: _notificationsEnabled,
                                      memo: '',
                                      createdAt: DateTime.now(),
                                    );
                                    try {
                                      await widget.onSubmit(next);
                                      if (!mounted) return;
                                      Navigator.of(this.context).popUntil((route) => route.isFirst);
                                    } catch (e) {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(content: Text('다음 일정 추가 중 오류가 발생했어요: $e')));
                                    }
                                  },
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('추가'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final company = _companyController.text.trim();
    final title = _titleController.text.trim();
    final link = _linkController.text.trim();
    if (company.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('회사명은 필수예요.')));
      return;
    }
    if (_deadlineAt.isAfter(DateTime(2100))) return;

    setState(() => _submitting = true);
    try {
      final next = widget.initial.copyWith(
        companyName: company,
        jobTitle: title,
        linkUrl: link,
        salary: _salaryController.text.trim(),
        deadlineAt: _deadlineAt,
        status: _status,
        outcome: _outcome,
        notificationsEnabled: _notificationsEnabled,
        memo: _memoController.text.trim(),
      );
      await widget.onSubmit(next);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('저장 완료')));
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 중 오류가 발생했어요: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom + 8;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15.0);
    const fieldHeight = 44.0;
    const fieldSpacing = 14.0;

    InputDecoration compactDecoration(String label) {
      return InputDecoration(
        labelText: label,
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        labelStyle: TextStyle(fontSize: 14.0, color: colorScheme.onSurfaceVariant),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              Row(
                children: [
                  Text(
                    widget.initial.site.label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (_linkController.text.trim().isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '원본 링크 포함',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (widget.warnings.isNotEmpty) ...[
                Card(
                  color: colorScheme.errorContainer,
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('확인이 필요해요', style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 4),
                        for (final w in widget.warnings)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Text('• $w', style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 12)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                height: fieldHeight,
                child: TextField(
                  controller: _companyController,
                  textInputAction: TextInputAction.next,
                  style: textStyle,
                  decoration: compactDecoration('회사명 (필수)'),
                ),
              ),
              const SizedBox(height: fieldSpacing),
              SizedBox(
                height: fieldHeight,
                child: TextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  style: textStyle,
                  decoration: compactDecoration('직무/공고 제목 (선택)'),
                ),
              ),
              const SizedBox(height: fieldSpacing),
              SizedBox(
                height: fieldHeight,
                child: InkWell(
                  onTap: _pickDeadline,
                  borderRadius: BorderRadius.circular(8),
                  child: InputDecorator(
                    decoration: compactDecoration('마감일 (필수)'),
                    child: Row(
                      children: [
                        Expanded(child: Text(DateFormatters.ymd.format(_deadlineAt), style: textStyle)),
                        const SizedBox(width: 8),
                        const Icon(Icons.event, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: fieldSpacing),
              SizedBox(
                height: fieldHeight,
                child: TextField(
                  controller: _linkController,
                  style: textStyle,
                  decoration: compactDecoration('공고 링크 (선택)'),
                  keyboardType: TextInputType.url,
                ),
              ),
              const SizedBox(height: fieldSpacing),
              SizedBox(
                height: fieldHeight,
                child: TextField(
                  controller: _salaryController,
                  style: textStyle,
                  decoration: compactDecoration('급여 (선택)'),
                  textInputAction: TextInputAction.next,
                ),
              ),
              const SizedBox(height: fieldSpacing),
              LayoutBuilder(
                builder: (context, constraints) {
                  final dropdownWidth = (constraints.maxWidth - 128).clamp(160.0, constraints.maxWidth);
                  final stageEnabled = _outcome == JobOutcome.none;
                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Opacity(
                              opacity: stageEnabled ? 1 : 0.55,
                              child: SizedBox(
                                height: fieldHeight,
                                child: DropdownMenu<JobStatus>(
                                  width: dropdownWidth,
                                  initialSelection: _status,
                                  onSelected: stageEnabled
                                      ? (v) {
                                          if (v == null) return;
                                          setState(() => _status = v);
                                        }
                                      : null,
                                  textStyle: textStyle,
                                  dropdownMenuEntries: kPipelineStageOptions
                                      .map((s) => DropdownMenuEntry<JobStatus>(
                                            value: s,
                                            label: s.label,
                                            style: ButtonStyle(
                                              textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 15)),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                          ))
                                      .toList(growable: false),
                                  label: const Text('상태', style: TextStyle(fontSize: 14.0)),
                                  inputDecorationTheme: InputDecorationTheme(
                                    isDense: true,
                                    filled: false,
                                    constraints: const BoxConstraints.tightFor(height: fieldHeight),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                                    ),
                                    labelStyle: TextStyle(fontSize: 14.0, color: colorScheme.onSurfaceVariant),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: fieldHeight,
                            child: ToggleButtons(
                              isSelected: <bool>[
                                _outcome == JobOutcome.passed,
                                _outcome == JobOutcome.failed,
                              ],
                              onPressed: (index) async {
                                final prev = _outcome;
                                final nextOutcome = index == 0
                                    ? (_outcome == JobOutcome.passed ? JobOutcome.none : JobOutcome.passed)
                                    : (_outcome == JobOutcome.failed ? JobOutcome.none : JobOutcome.failed);

                                final openNext = nextOutcome == JobOutcome.passed && prev != JobOutcome.passed;
                                final showEncouragement = nextOutcome == JobOutcome.failed && prev != JobOutcome.failed;
                                setState(() {
                                  _outcome = nextOutcome;
                                });
                                if (openNext && mounted) {
                                  final ok = await _saveCurrentSilently();
                                  if (!ok || !mounted) return;
                                  await _openNextStepSheet();
                                } else if (showEncouragement && mounted) {
                                  const messages = [
                                    '아쉽지만 괜찮아요. 다음 기회가 있어요.',
                                    '수고했어요. 이번 경험이 다음 합격으로 이어질 거예요.',
                                    '오늘은 여기까지. 잠깐 쉬고 다시 가보자.',
                                  ];
                                  final msg = messages[_rng.nextInt(messages.length)];
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              constraints: const BoxConstraints.tightFor(height: fieldHeight, width: 56),
                              textStyle: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w700),
                              children: const [
                                Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('합격')),
                                Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('불합격')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -2),
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
                title: Text('마감 임박 알림 받기', style: textStyle?.copyWith(fontWeight: FontWeight.w600, fontSize: 14.0)),
              ),
              const SizedBox(height: fieldSpacing),
              TextField(
                controller: _memoController,
                style: textStyle,
                decoration: compactDecoration('메모 (선택)'),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
          child: Row(
            children: [
              if (widget.allowDelete && widget.onDelete != null) ...[
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('삭제 확인'),
                                content: const Text('정말 삭제하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(true),
                                    style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                                    child: const Text('삭제'),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await widget.onDelete!.call();
                              if (!context.mounted) return;
                              Navigator.of(context).pop();
                            }
                          },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
                    ),
                    child: const Text('삭제', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _submitting
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(widget.submitLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
