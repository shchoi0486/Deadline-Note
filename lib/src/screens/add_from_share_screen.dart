import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/job_link_parser.dart';
import '../state/app_state_scope.dart';
import '../widgets/deadline_editor_form.dart';

class AddFromShareScreen extends StatefulWidget {
  const AddFromShareScreen({required this.sharedText, super.key});

  final String? sharedText;

  @override
  State<AddFromShareScreen> createState() => _AddFromShareScreenState();
}

class _AddFromShareScreenState extends State<AddFromShareScreen> {
  final _urlController = TextEditingController();
  bool _loading = false;
  ParsedJobLink? _parsed;
  List<String> _warnings = const <String>[];

  @override
  void initState() {
    super.initState();
    final initial = widget.sharedText;
    if (initial != null) {
      final url = _extractFirstUrl(initial) ?? initial.trim();
      _urlController.text = url;
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _parse(url);
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? _extractFirstUrl(String input) {
    final match = RegExp(r'https?://\S+').firstMatch(input);
    return match?.group(0);
  }

  Future<void> _parse(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _loading = true;
      _warnings = const <String>[];
      _parsed = null;
    });
    try {
      final appState = AppStateScope.of(context);
      final parsed = await appState.parseSharedUrl(trimmed);
      if (!mounted) return;
      setState(() {
        _parsed = parsed;
        _warnings = parsed.warnings;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _warnings = const <String>['링크 분석에 실패했어요. 직접 입력으로 전환해 주세요.'];
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runUrlAction() async {
    if (_loading) return;
    var text = _urlController.text.trim();
    if (text.isEmpty) {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final clip = data?.text?.trim();
      if (clip != null && clip.isNotEmpty) {
        text = _extractFirstUrl(clip) ?? clip;
        if (mounted) _urlController.text = text;
      }
    }
    if (text.isEmpty) return;
    await _parse(text);
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final parsed = _parsed;
    final autoMode = widget.sharedText != null;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 일정/현황 화면과 동일한 커스텀 헤더 구조 적용
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
                                  autoMode ? '공유로 추가' : '추가',
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
                  // 일정 화면의 우측 아이콘 공간과 맞춤
                  const SizedBox(width: 32 + 32 + 14),
                ],
              ),
            ),
            if (!autoMode)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: '공고 URL',
                    suffixIcon: IconButton(
                      onPressed: _loading ? null : _runUrlAction,
                      icon: const Icon(Icons.arrow_circle_right),
                      tooltip: '입력',
                    ),
                  ),
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.go,
                  onSubmitted: (_) => _runUrlAction(),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _loading ? '공고 정보를 정리하는 중…' : '공유된 공고를 확인해 주세요',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (!_loading)
                      IconButton.filledTonal(
                        onPressed: _runUrlAction,
                        icon: const Icon(Icons.arrow_circle_right),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (parsed == null
                      ? Padding(
                          padding: const EdgeInsets.all(16),
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              _warnings.isNotEmpty ? _warnings.join('\n') : '사람인/잡코리아 등에서 “공유”로 링크를 보내면 자동으로 채워져요.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: _warnings.isNotEmpty ? Theme.of(context).colorScheme.error : null,
                                  ),
                            ),
                          ),
                        )
                      : DeadlineEditorForm(
                          initial: appState.createDeadlineFromParsed(parsed).copyWith(
                                deadlineAt: parsed.deadlineAt ??
                                    (() {
                                      final base = DateTime.now().add(const Duration(days: 7));
                                      return DateTime(base.year, base.month, base.day, 23, 59);
                                    })(),
                              ),
                          warnings: _warnings,
                          submitLabel: '저장',
                          onSubmit: (next) => appState.upsertDeadline(next),
                        )),
            ),
          ],
        ),
      ),
    );
  }
}
