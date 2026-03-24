import 'dart:math';

import 'package:flutter/material.dart';
import 'package:deadline_note/l10n/app_localizations.dart';

import '../models/deadline_type.dart';
import '../models/job_deadline.dart';
import '../models/job_site.dart';
import '../models/job_status.dart';
import '../ui/date_formatters.dart';
import '../utils/ad_manager.dart';

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
  final Future<void> Function(JobDeadline next, {bool silent}) onSubmit;
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
  late DeadlineType _deadlineType;
  late bool _isEstimated;
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
    _deadlineType = widget.initial.deadlineType;
    _isEstimated = widget.initial.isEstimated;
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

  DateTime _atEndOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 18, 0);

  Future<bool> _saveCurrentSilently() async {
    final l10n = AppLocalizations.of(context)!;
    if (_submitting) return false;
    final company = _companyController.text.trim();
    if (company.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.companyNameRequiredMsg)));
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
        deadlineType: _deadlineType,
        status: _status,
        outcome: _outcome,
        notificationsEnabled: _notificationsEnabled,
        memo: _memoController.text.trim(),
        isEstimated: _isEstimated,
      );
      await widget.onSubmit(next, silent: true);
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
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
    setState(() {
      _deadlineAt = _atEndOfDay(picked);
      // 수동으로 날짜를 선택하면 더 이상 '예상'이 아님 (상시채용 제외)
      if (_deadlineType == DeadlineType.fixedDate) {
        _isEstimated = false;
      }
    });
  }

  Future<void> _openNextStepSheet() async {
    final pipeline = kPipelineStageOptions;
    final currentIndex = pipeline.indexOf(_status);
    final nextStageOptions = currentIndex >= 0
        ? pipeline.skip(currentIndex + 1).toList(growable: false)
        : pipeline.where((s) => s != JobStatus.document).toList(growable: false);
    if (nextStageOptions.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.noNextStepMsg)));
      return;
    }

    var nextStage = nextStageOptions.first;
    final base = DateFormatters.dateOnly(_deadlineAt).add(const Duration(days: 7));
    var nextDate = _atEndOfDay(base);

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final viewInsetsBottom = MediaQuery.of(context).viewInsets.bottom;
        final safeBottom = MediaQuery.of(context).padding.bottom;

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
            final l10n = AppLocalizations.of(context)!;
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(bottom: viewInsetsBottom + 16),
                child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.nextStep, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: nextStageOptions.map((s) {
                            final isSelected = nextStage == s;
                            return ChoiceChip(
                              label: Text(
                                s.localizedLabel(l10n),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? cs.onPrimary : cs.onSurface,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: cs.primary,
                              backgroundColor: cs.surfaceContainerHigh,
                              checkmarkColor: cs.onPrimary,
                              onSelected: (selected) {
                                if (selected) {
                                  setModalState(() => nextStage = s);
                                }
                              },
                              side: BorderSide(
                                color: isSelected ? cs.primary : Colors.grey.withOpacity(0.2),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 44,
                          child: InkWell(
                            onTap: () => pickNextDate(setModalState),
                            borderRadius: BorderRadius.circular(8),
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: l10n.date,
                                isDense: true,
                                filled: false,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
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
                                child: Text(l10n.cancel),
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
                                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.companyNameRequiredMsg)));
                                          return;
                                        }

                                        final next = JobDeadline(
                                          id: _randomId(),
                                          companyName: company,
                                          jobTitle: _titleController.text.trim(),
                                          deadlineAt: nextDate,
                                          deadlineType: _deadlineType,
                                          linkUrl: _linkController.text.trim(),
                                          site: widget.initial.site,
                                          salary: _salaryController.text.trim(),
                                          status: nextStage,
                                          outcome: JobOutcome.none,
                                          notificationsEnabled: _notificationsEnabled,
                                          memo: '',
                                          createdAt: DateTime.now(),
                                          isEstimated: _isEstimated,
                                          previousStepId: widget.initial.id,
                                        );
                                        try {
                                          // 1. 바텀 시트 먼저 닫기
                                          if (context.mounted) {
                                            Navigator.of(context).pop();
                                          }

                                          // 2. 데이터 저장 (HomeShell의 리스너가 감지하여 탭 이동 및 팝 처리를 수행함)
                                          await widget.onSubmit(next, silent: false);
                                          
                                          // 3. 광고 표시 (저장 후 UX 흐름상 표시)
                                          if (context.mounted) {
                                            await AdManager.showNativeAdDialog(context);
                                          }
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(content: Text(l10n.addNextStepError(e.toString()))));
                                        }
                                      },
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(l10n.add),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ),
            );
          },
        );
        },
      );
    }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (_submitting) return;
    final company = _companyController.text.trim();
    final title = _titleController.text.trim();
    final link = _linkController.text.trim();
    if (company.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.companyNameRequiredMsg)));
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
        deadlineType: _deadlineType,
        status: _status,
        outcome: _outcome,
        notificationsEnabled: _notificationsEnabled,
        memo: _memoController.text.trim(),
        isEstimated: _isEstimated,
      );
      await widget.onSubmit(next, silent: false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveComplete)));
      }
      
      // 저장 후 광고 표시 (UX를 위해 네이티브 다이얼로그 형태로 표시)
      if (mounted) {
        final navigator = Navigator.of(context);
        await AdManager.showNativeAdDialog(context);

        if (navigator.canPop()) {
          navigator.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.saveError(e.toString()))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = max(MediaQuery.of(context).padding.bottom, 40.0);
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14.0);
    const fieldHeight = 40.0;
    const fieldSpacing = 12.0;

    InputDecoration compactDecoration(String label) {
      return InputDecoration(
        labelText: label,
        isDense: true,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        labelStyle: TextStyle(fontSize: 12.0, color: colorScheme.onSurfaceVariant),
      );
    }

    final formFields = [
      Text(
        l10n.jobInfo(widget.initial.site.localizedLabel(l10n)),
        style: textStyle?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 14.0,
        ),
      ),
      const SizedBox(height: 6),
      if (widget.warnings.isNotEmpty) ...[
        Card(
          color: colorScheme.errorContainer,
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.checkRequired,
                    style: TextStyle(color: colorScheme.onErrorContainer, fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 2),
                for (final w in widget.warnings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 1),
                    child: Text('• $w', style: TextStyle(color: colorScheme.onErrorContainer, fontSize: 11)),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
      SizedBox(
        height: fieldHeight,
        child: TextField(
          controller: _companyController,
          textInputAction: TextInputAction.next,
          style: textStyle,
          decoration: compactDecoration(l10n.companyRequired),
        ),
      ),
      const SizedBox(height: fieldSpacing),
      SizedBox(
        height: fieldHeight,
        child: TextField(
          controller: _titleController,
          textInputAction: TextInputAction.next,
          style: textStyle,
          decoration: compactDecoration(l10n.jobTitleOptional),
        ),
      ),
      const SizedBox(height: fieldSpacing),
      SizedBox(
        height: fieldHeight,
        child: InkWell(
          onTap: _pickDeadline,
          borderRadius: BorderRadius.circular(8),
          child: InputDecorator(
            decoration: compactDecoration(_deadlineType == DeadlineType.rolling ? l10n.estimatedDeadline : l10n.deadlineRequired),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        _deadlineType == DeadlineType.rolling
                            ? '${DateFormatters.ymd.format(_deadlineAt)}${l10n.rollingEstimated}'
                            : DateFormatters.ymd.format(_deadlineAt),
                        style: textStyle,
                      ),
                      if (_isEstimated && _deadlineType != DeadlineType.rolling) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.estimated,
                            style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
          decoration: compactDecoration(l10n.linkOptional),
          keyboardType: TextInputType.url,
        ),
      ),
      const SizedBox(height: fieldSpacing),
      SizedBox(
        height: fieldHeight,
        child: TextField(
          controller: _salaryController,
          style: textStyle,
          decoration: compactDecoration(l10n.salaryOptional),
          textInputAction: TextInputAction.next,
        ),
      ),
      const SizedBox(height: fieldSpacing),
      LayoutBuilder(
        builder: (context, constraints) {
          final dropdownWidth = (constraints.maxWidth - 120).clamp(140.0, constraints.maxWidth);
          final stageEnabled = _outcome == JobOutcome.none;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
                          textStyle: textStyle?.copyWith(fontSize: 14),
                          dropdownMenuEntries: kPipelineStageOptions
                              .map((s) => DropdownMenuEntry<JobStatus>(
                                    value: s,
                                    label: s.localizedLabel(l10n),
                                    style: ButtonStyle(
                                      textStyle: WidgetStateProperty.all(const TextStyle(fontSize: 14)),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ))
                              .toList(growable: false),
                          label: Text(l10n.status, style: const TextStyle(fontSize: 12.0)),
                          inputDecorationTheme: InputDecorationTheme(
                            isDense: true,
                            filled: false,
                            constraints: const BoxConstraints.tightFor(height: fieldHeight),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 11, vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                            ),
                            labelStyle: TextStyle(fontSize: 12.0, color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
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
                          final messages = [
                            l10n.encouragement1,
                            l10n.encouragement2,
                            l10n.encouragement3,
                          ];
                          final msg = messages[_rng.nextInt(messages.length)];
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      borderColor: colorScheme.primary.withOpacity(0.5), // 기본 테두리를 연한 파란색으로
                      selectedBorderColor: colorScheme.primary, // 선택 시 진한 파란색
                      fillColor: colorScheme.primary.withOpacity(0.1), // 선택 시 연한 파란색 배경
                      selectedColor: colorScheme.primary, // 선택 시 글자색
                      color: colorScheme.onSurfaceVariant, // 비선택 시 글자색
                      constraints: const BoxConstraints.tightFor(height: fieldHeight, width: 52),
                      textStyle: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w900),
                      children: [
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(l10n.passed)),
                        Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: Text(l10n.failed)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
      const SizedBox(height: 2),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l10n.notificationEnable, style: textStyle?.copyWith(fontWeight: FontWeight.w600, fontSize: 12.0)),
          SizedBox(
            height: 28,
            child: Transform.scale(
              scale: 0.8,
              child: Switch(
                value: _notificationsEnabled,
                onChanged: (v) => setState(() => _notificationsEnabled = v),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      TextField(
        controller: _memoController,
        style: textStyle,
        decoration: compactDecoration(l10n.memoOptional),
        minLines: 1,
        maxLines: 3,
      ),
    ];

    final bottomButtons = Padding(
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
                            title: Text(l10n.confirmDelete),
                            content: Text(l10n.confirmDeleteContent),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                                child: Text(l10n.delete),
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
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                ),
                child: Text(l10n.delete, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _submitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(widget.submitLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight != double.infinity) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  children: formFields,
                ),
              ),
              bottomButtons,
            ],
          );
        } else {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: formFields,
                ),
              ),
              bottomButtons,
            ],
          );
        }
      },
    );
  }
}
