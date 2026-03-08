import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:deadline_note/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import 'add_manual_screen.dart';
import '../services/job_link_parser.dart';
import '../models/job_site.dart';
import '../models/deadline_type.dart';
import '../state/app_state_scope.dart';
import '../widgets/ad_placeholder.dart';
import '../widgets/deadline_editor_form.dart';
import 'webview_scrape_screen.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return;
    setState(() {
      _loading = true;
      _warnings = const <String>[];
      _parsed = null;
    });
    try {
      final appState = AppStateScope.of(context);
      final parsed = await appState.parseSharedUrl(trimmed, sharedText: widget.sharedText);
      if (!mounted) return;
      setState(() {
        _parsed = parsed;
        _warnings = parsed.warnings;
      });
      final needWebView = parsed.site == JobSite.indeed && ((parsed.companyName.isEmpty && parsed.jobTitle.isEmpty) || parsed.warnings.contains('parseErrorMsg'));
      if (needWebView) {
        final result = await Navigator.of(context).push<Map<String, String>>(MaterialPageRoute(builder: (_) => WebviewScrapeScreen(targetUrl: trimmed)));
        if (!mounted) return;
        if (result != null) {
          final company = (result['companyName'] ?? '').trim();
          final title = (result['jobTitle'] ?? '').trim();
          final salary = (result['salary'] ?? '').trim();
          if (company.isNotEmpty || title.isNotEmpty) {
            setState(() {
              _parsed = ParsedJobLink(
                url: Uri.parse(trimmed),
                site: JobSite.indeed,
                companyName: company,
                jobTitle: title,
                deadlineAt: DateTime.now().add(const Duration(days: 14)),
                deadlineType: DeadlineType.rolling,
                salary: salary,
                warnings: const <String>[],
                isEstimated: true,
              );
              _warnings = const <String>[];
            });
          }
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _warnings = [l10n.parseErrorMsg];
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

  String _localizeWarning(String key, AppLocalizations l10n) {
    switch (key) {
      case 'parseWarningDeadline':
        return l10n.parseWarningDeadline;
      case 'parseWarningCompany':
        return l10n.parseWarningCompany;
      case 'parseWarningTitle':
        return l10n.parseWarningTitle;
      case 'parseErrorMsg':
        return l10n.parseErrorMsg;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = AppStateScope.of(context);
    final parsed = _parsed;
    final autoMode = widget.sharedText != null;
    final cs = Theme.of(context).colorScheme;

    final localizedWarnings = _warnings.map((w) => _localizeWarning(w, l10n)).toList();

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // Header
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
                              backgroundColor: cs.primary.withValues(alpha: 0.1),
                              foregroundColor: cs.primary,
                              child: const Icon(Icons.person, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  autoMode ? l10n.settingsShareAdd : l10n.tabAdd,
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
                      // Center: Empty
                      const SizedBox.shrink(),
                      // Right: Actions (Empty for consistency)
                      const Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(width: 24 * 3 + 8 * 2),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const AdPlaceholder(),
              // Fixed Top Content: URL Input & Manual Add Button
              if (!autoMode)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 42,
                              child: TextField(
                                controller: _urlController,
                                textAlignVertical: TextAlignVertical.center,
                                decoration: InputDecoration(
                                  hintText: l10n.jobPostUrl,
                                  prefixIcon: Icon(Icons.link_rounded, size: 18, color: cs.primary),
                                  filled: false,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(color: cs.primary, width: 1.5),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                                  isDense: true,
                                ),
                                style: const TextStyle(fontSize: 14),
                                keyboardType: TextInputType.url,
                                textInputAction: TextInputAction.go,
                                onSubmitted: (_) => _runUrlAction(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 42,
                            width: 42,
                            child: IconButton.filled(
                              onPressed: _loading ? null : _runUrlAction,
                              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () async {
                          final url = _urlController.text.trim();
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddManualScreen(prefillUrl: url.isEmpty ? null : url),
                            ),
                          );
                        },
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: Text(l10n.addMethodManual, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        style: FilledButton.styleFrom(
                          backgroundColor: cs.secondaryContainer,
                          foregroundColor: cs.onSecondaryContainer,
                          padding: const EdgeInsets.symmetric(vertical: 0),
                          minimumSize: const Size.fromHeight(38),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _loading ? l10n.parsingInProgress : l10n.checkSharedPost,
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
              // Bottom Content: Quick Links OR Parsing Result
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : parsed != null
                        ? DeadlineEditorForm(
                            initial: appState.createDeadlineFromParsed(parsed).copyWith(
                                  deadlineAt: parsed.deadlineAt ??
                                      (() {
                                        final base = DateTime.now().add(const Duration(days: 14));
                                        return DateTime(base.year, base.month, base.day, 18, 0);
                                      })(),
                                ),
                            warnings: localizedWarnings,
                            submitLabel: l10n.save,
                            onSubmit: (next, {silent = false}) => appState.upsertDeadline(next, incrementRevision: !silent),
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                if (!autoMode)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: _buildQuickLinks(context),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          localizedWarnings.isNotEmpty ? localizedWarnings.join('\n') : l10n.shareInstruction,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: localizedWarnings.isNotEmpty ? Theme.of(context).colorScheme.error : null,
                                              ),
                                        ),
                                        const SizedBox(height: 24),
                                        Center(
                                          child: TextButton.icon(
                                            onPressed: () => _showHowToUse(context),
                                            icon: const Icon(Icons.help_outline_rounded, size: 20),
                                            label: Text(l10n.howToUse, style: const TextStyle(fontWeight: FontWeight.w600)),
                                            style: TextButton.styleFrom(
                                              foregroundColor: cs.primary,
                                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                              backgroundColor: cs.primary.withValues(alpha: 0.05),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 40),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHowToUse(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                l10n.howToUseTitle,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildHowToStep(
                    l10n.howToStep1Title,
                    l10n.howToStep1Desc,
                    'assets/images/onboarding/ins1.png',
                    highlightAlignment: const Alignment(0.98, -0.15),
                  ),
                  const SizedBox(height: 32),
                  _buildHowToStep(
                    l10n.howToStep2Title,
                    l10n.howToStep2Desc,
                    'assets/images/onboarding/ins2.png',
                    highlightAlignment: const Alignment(0.85, -0.78),
                  ),
                  const SizedBox(height: 40),
                  _buildHowToStep(
                    l10n.howToStep3Title,
                    l10n.howToStep3Desc,
                    'assets/images/onboarding/ins3.png',
                    highlightAlignment: const Alignment(0.09, 0.25),
                  ),
                  const SizedBox(height: 32),
                  _buildHowToStep(
                    l10n.howToStep4Title,
                    l10n.howToStep4Desc,
                    'assets/images/onboarding/ins4.png',
                    highlightAlignment: const Alignment(0.0, 0.71),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                  ),
                  child: Text(l10n.ok, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowToStep(String title, String description, String imagePath, {Alignment? highlightAlignment}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
        const SizedBox(height: 6),
        Text(
          description,
          style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.4),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                  ),
                ),
                if (highlightAlignment != null)
                  Positioned.fill(
                    child: Align(
                      alignment: highlightAlignment,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.red, width: 3),
                          color: Colors.red.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    final lang = Localizations.localeOf(context).languageCode;
    final cs = Theme.of(context).colorScheme;

    final sitesMap = {
      'ko': [
        {'name': '사람인', 'url': 'https://www.saramin.co.kr', 'icon': 'https://www.saramin.co.kr/favicon.ico'},
        {'name': '잡코리아', 'url': 'https://www.jobkorea.co.kr', 'icon': 'https://www.jobkorea.co.kr/favicon.ico'},
        {'name': '인크루트', 'url': 'https://www.incruit.com', 'icon': 'https://www.incruit.com/favicon.ico'},
        {'name': '알바몬', 'url': 'https://www.albamon.com', 'icon': 'https://www.albamon.com/favicon.ico'},
        {'name': '알바천국', 'url': 'https://www.alba.co.kr', 'icon': 'https://www.alba.co.kr/favicon.ico'},
        {'name': '원티드', 'url': 'https://www.wanted.co.kr', 'icon': 'https://www.wanted.co.kr/favicon.ico'},
      ],
      'en': [
        {'name': 'Indeed', 'url': 'https://www.indeed.com', 'icon': 'https://www.indeed.com/favicon.ico'},
        {'name': 'LinkedIn', 'url': 'https://www.linkedin.com', 'icon': 'https://static.licdn.com/sc/h/al2o9zrvru7aqj8e1x2rzsrca'},
        {'name': 'Glassdoor', 'url': 'https://www.glassdoor.com', 'icon': 'https://www.glassdoor.com/favicon.ico'},
        {'name': 'Monster', 'url': 'https://www.monster.com', 'icon': 'https://www.monster.com/favicon.ico'},
        {'name': 'ZipRecruiter', 'url': 'https://www.ziprecruiter.com', 'icon': 'https://www.ziprecruiter.com/favicon.ico'},
        {'name': 'SimplyHired', 'url': 'https://www.simplyhired.com', 'icon': 'https://www.simplyhired.com/favicon.ico'},
      ],
      'ja': [
        {'name': 'Indeed Japan', 'url': 'https://jp.indeed.com', 'icon': 'https://jp.indeed.com/favicon.ico'},
        {'name': 'Rikunabi', 'url': 'https://www.rikunabi.com', 'icon': 'https://www.rikunabi.com/favicon.ico'},
        {'name': 'Mynavi', 'url': 'https://www.mynavi.jp', 'icon': 'https://www.mynavi.jp/favicon.ico'},
        {'name': 'Wantedly', 'url': 'https://www.wantedly.com', 'icon': 'https://www.wantedly.com/favicon.ico'},
        {'name': 'Doda', 'url': 'https://doda.jp', 'icon': 'https://doda.jp/favicon.ico'},
        {'name': 'En Japan', 'url': 'https://www.en-japan.com', 'icon': 'https://www.en-japan.com/favicon.ico'},
      ],
      'zh': [
        {'name': '51job', 'url': 'https://www.51job.com', 'icon': 'https://www.51job.com/favicon.ico'},
        {'name': 'Zhaopin', 'url': 'https://www.zhaopin.com', 'icon': 'https://www.zhaopin.com/favicon.ico'},
        {'name': 'Boss Zhipin', 'url': 'https://www.zhipin.com', 'icon': 'https://www.zhipin.com/favicon.ico'},
        {'name': 'Liepin', 'url': 'https://www.liepin.com', 'icon': 'https://www.liepin.com/favicon.ico'},
        {'name': 'Lagou', 'url': 'https://www.lagou.com', 'icon': 'https://www.lagou.com/favicon.ico'},
        {'name': 'LinkedIn', 'url': 'https://www.linkedin.com', 'icon': 'https://static.licdn.com/sc/h/al2o9zrvru7aqj8e1x2rzsrca'},
      ],
      'hi': [
        {'name': 'Naukri', 'url': 'https://www.naukri.com', 'icon': 'https://www.naukri.com/favicon.ico'},
        {'name': 'Indeed India', 'url': 'https://in.indeed.com', 'icon': 'https://in.indeed.com/favicon.ico'},
        {'name': 'LinkedIn', 'url': 'https://www.linkedin.com', 'icon': 'https://static.licdn.com/sc/h/al2o9zrvru7aqj8e1x2rzsrca'},
        {'name': 'foundit', 'url': 'https://www.foundit.in', 'icon': 'https://www.foundit.in/favicon.ico'},
        {'name': 'Shine', 'url': 'https://www.shine.com', 'icon': 'https://www.shine.com/favicon.ico'},
        {'name': 'Freshersworld', 'url': 'https://www.freshersworld.com', 'icon': 'https://www.freshersworld.com/favicon.ico'},
      ],
    };

    // 기본값은 영어(en)로 설정
    final sites = sitesMap[lang] ?? sitesMap['en']!;
    
    // 지원하지 않는 언어이거나 사이트 목록이 비어있으면 표시하지 않음 (단, en fallback이 있으므로 거의 발생 안 함)
    if (sites.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.recommendedJobSites,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
          ),
          itemCount: sites.length,
          itemBuilder: (context, index) {
            final site = sites[index];
            return Material(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () async {
                  final uri = Uri.parse(site['url']!);
                  try {
                    bool launched = await launchUrl(
                      uri,
                      mode: LaunchMode.externalNonBrowserApplication,
                    );
                    if (!launched) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  } catch (_) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          site['icon']!,
                          width: 24,
                          height: 24,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.language, size: 24, color: cs.primary),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          site['name']!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
