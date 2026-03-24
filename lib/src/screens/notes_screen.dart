import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:deadline_note/l10n/app_localizations.dart';

import 'package:url_launcher/url_launcher.dart';
import 'job_browser_screen.dart';

import '../models/company_note.dart';
import '../models/interview_notes.dart';
import '../models/job_deadline.dart';
import '../models/job_status.dart';
import '../services/storage_service.dart';
import '../services/company_info_service.dart';
import '../ui/date_formatters.dart';
import '../state/app_state_scope.dart';
import '../widgets/ad_placeholder.dart';
import '../widgets/native_ad_dialog.dart';
import '../services/rewarded_ad_service.dart';

String _cleanCompanyName(String name) {
  if (name.isEmpty) return name;
  
  // 1. Remove bracketed corporate suffixes more aggressively
  // Matches: (주), ( 주 ), （주）, (주식회사), (유), (사), (재), (복), ㈜, etc.
  // Also handles full-width brackets （ ）
  final patterns = [
    r'[\(（][\s]*주[\s]*[\)）]',
    r'[\(（][\s]*주식회사[\s]*[\)）]',
    r'주식회사[\s]+',
    r'[\s]+주식회사',
    r'[\(（][\s]*유[\s]*[\)）]',
    r'[\(（][\s]*유한회사[\s]*[\)）]',
    r'유한회사[\s]+',
    r'[\s]+유한회사',
    r'[\(（][\s]*재[\s]*[\)）]',
    r'[\(（][\s]*재단법인[\s]*[\)）]',
    r'재단법인[\s]+',
    r'[\s]+재단법인',
    r'[\(（][\s]*사[\s]*[\)）]',
    r'[\(（][\s]*사단법인[\s]*[\)）]',
    r'사단법인[\s]+',
    r'[\s]+사단법인',
    r'[\(（][\s]*복[\s]*[\)）]',
    r'[\(（][\s]*의[\s]*[\)）]',
    r'[\(（][\s]*의료[\s]*[\)）]',
    r'[\(（][\s]*의료법인[\s]*[\)）]',
    r'[\(（][\s]*학[\s]*[\)）]',
    r'[\(（][\s]*학교법인[\s]*[\)）]',
    r'㈜',
  ];

  String cleaned = name;
  for (var p in patterns) {
    cleaned = cleaned.replaceAll(RegExp(p), '');
  }

  // 2. Remove any remaining bracketed single characters if they look like corporate markers
  // e.g. (합), (합자), (특), (유)
  cleaned = cleaned.replaceAll(RegExp(r'[\(（][\s]*[주유사재복의학특합][\s]*[\)）]'), '');

  // 3. Final trim and remove redundant spaces
  return cleaned.trim().replaceAll(RegExp(r'\s+'), ' ');
}

class _SearchLink {
  final String label;
  final String url;
  final Color color;
  final IconData icon;

  const _SearchLink(this.label, this.url, this.color, this.icon);
}

List<_SearchLink> _getSearchLinks(BuildContext context, String companyName) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).languageCode;
  final encodedName = Uri.encodeComponent(_cleanCompanyName(companyName));

  if (locale == 'ko') {
    return [
      _SearchLink(l10n.searchNaver, 'https://search.naver.com/search.naver?query=$encodedName', const Color(0xFF03C75A), Icons.search),
      _SearchLink(l10n.searchJobPlanet, 'https://www.jobplanet.co.kr/search?query=$encodedName', const Color(0xFF00C362), Icons.business),
      _SearchLink(l10n.searchBlind, 'https://www.teamblind.com/kr/search/$encodedName', const Color(0xFFEB1C2D), Icons.chat_bubble_outline),
      _SearchLink(l10n.searchCatch, 'https://www.catch.co.kr/Search/SearchList?Keyword=$encodedName', const Color(0xFF7C4DFF), Icons.school),
      _SearchLink(l10n.searchGoogle, 'https://www.google.com/search?q=$encodedName', const Color(0xFF4285F4), Icons.language),
    ];
  } else if (locale == 'ja') {
    return [
      _SearchLink(l10n.searchGoogle, 'https://www.google.co.jp/search?q=$encodedName', const Color(0xFF4285F4), Icons.language),
      _SearchLink(l10n.searchOpenWork, 'https://www.vorkers.com/company_list?name=$encodedName', const Color(0xFF2C6ECB), Icons.business),
      _SearchLink(l10n.searchEnLighthouse, 'https://en-hyouban.com/search/?q=$encodedName', const Color(0xFF00B900), Icons.star_half),
      _SearchLink(l10n.searchLinkedIn, 'https://www.linkedin.com/search/results/companies/?keywords=$encodedName', const Color(0xFF0A66C2), Icons.work),
      _SearchLink(l10n.searchYahoo, 'https://search.yahoo.co.jp/search?p=$encodedName', const Color(0xFFFF0033), Icons.search),
    ];
  } else if (locale == 'zh') {
    return [
      _SearchLink(l10n.searchBaidu, 'https://www.baidu.com/s?wd=$encodedName', const Color(0xFF2932E1), Icons.search),
      _SearchLink(l10n.searchKanzhun, 'https://www.kanzhun.com/search/?q=$encodedName', const Color(0xFF5dd5c8), Icons.visibility),
      _SearchLink(l10n.searchMaimai, 'https://maimai.cn/web/search_center?type=company&query=$encodedName', const Color(0xFF0060FF), Icons.people),
      _SearchLink(l10n.searchGoogle, 'https://www.google.com/search?q=$encodedName', const Color(0xFF4285F4), Icons.language),
      _SearchLink(l10n.searchLinkedIn, 'https://www.linkedin.com/search/results/companies/?keywords=$encodedName', const Color(0xFF0A66C2), Icons.work),
    ];
  } else if (locale == 'hi') {
    return [
      _SearchLink(l10n.searchGoogle, 'https://www.google.co.in/search?q=$encodedName', const Color(0xFF4285F4), Icons.language),
      _SearchLink(l10n.searchLinkedIn, 'https://www.linkedin.com/search/results/companies/?keywords=$encodedName', const Color(0xFF0A66C2), Icons.work),
      _SearchLink(l10n.searchAmbitionBox, 'https://www.ambitionbox.com/search?q=$encodedName', const Color(0xFFF07C35), Icons.star),
      _SearchLink(l10n.searchGlassdoor, 'https://www.glassdoor.co.in/Search/results.htm?keyword=$encodedName', const Color(0xFF0CAA41), Icons.door_front_door),
      _SearchLink(l10n.searchIndeed, 'https://in.indeed.com/companies?q=$encodedName', const Color(0xFF2164f3), Icons.work_outline),
    ];
  } else {
    // Default (English and others)
    return [
      _SearchLink(l10n.searchGoogle, 'https://www.google.com/search?q=$encodedName', const Color(0xFF4285F4), Icons.language),
      _SearchLink(l10n.searchLinkedIn, 'https://www.linkedin.com/search/results/companies/?keywords=$encodedName', const Color(0xFF0A66C2), Icons.work),
      _SearchLink(l10n.searchGlassdoor, 'https://www.glassdoor.com/Search/results.htm?keyword=$encodedName', const Color(0xFF0CAA41), Icons.door_front_door),
      _SearchLink(l10n.searchIndeed, 'https://www.indeed.com/companies?q=$encodedName', const Color(0xFF2164f3), Icons.work_outline),
      _SearchLink(l10n.searchYahoo, 'https://search.yahoo.com/search?p=$encodedName', const Color(0xFF7B0099), Icons.search),
    ];
  }
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> with SingleTickerProviderStateMixin {
  final _storage = StorageService();
  late final TabController _tabController;

  bool _loading = true;
  List<CompanyNote> _companies = const <CompanyNote>[];
  List<InterviewSession> _sessions = const <InterviewSession>[];
  StreamSubscription<int>? _tabSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      // [수정] 탭 이동 완료 시 데이터 최신화 (다른 탭에서 추가된 일정 반영)
      if (!_tabController.indexIsChanging) {
        _load();
      }
    });
    _load();
    RewardedAdService.loadAd(); // 보상형 광고 미리 로드
    
    // 사용자가 요청한 네이티브 광고 다이얼로그 표시 (앱 실행 후 잠시 뒤)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = AppStateScope.of(context);
      _tabSub = appState.onTabChange.listen((index) {
        // [수정] Notes 탭이 다시 선택됨
        if (index == 3) {
          _load();
        }
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          // 광고 제거 요청으로 인해 비활성화
          // NativeAdDialog.show(context);
        }
      });
    });
  }

  @override
  void dispose() {
    _tabSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rawCompanies = await _storage.loadCompanyNotes();
      final rawSessions = await _storage.loadInterviewSessions();
      if (!mounted) return;

      final companies = rawCompanies.map(CompanyNote.fromJson).where((c) => c.id.isNotEmpty).toList(growable: false)
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      final sessions = rawSessions.map(InterviewSession.fromJson).where((s) => s.id.isNotEmpty).toList(growable: false)
        ..sort((a, b) => b.heldAt.compareTo(a.heldAt));

      setState(() {
        _companies = companies;
        _sessions = sessions;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveCompanies(List<CompanyNote> companies) async {
    await _storage.saveCompanyNotes(companies.map((c) => c.toJson()).toList(growable: false));
    if (!mounted) return;
    setState(() {
      _companies = companies.toList(growable: false)..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  Future<void> _saveSessions(List<InterviewSession> sessions) async {
    await _storage.saveInterviewSessions(sessions.map((s) => s.toJson()).toList(growable: false));
    if (!mounted) return;
    setState(() {
      _sessions = sessions.toList(growable: false)..sort((a, b) => b.heldAt.compareTo(a.heldAt));
    });
  }

  Future<void> _addCompany(Map<String, String> companyRoles) async {
    final now = DateTime.now();
    final emptyNote = CompanyNote(
      id: '${now.microsecondsSinceEpoch}',
      companyName: '',
      role: '',
      keywords: const [],
      pitch: '',
      risks: const [],
      summary: '',
      fit: '',
      newsSummary: '',
      businessDirection: '',
      jobConnection: '',
      riskPoints: '',
      expectedQuestions: '',
      stories: const [],
      questionBank: const [],
      updatedAt: now,
    );

    final created = await Navigator.of(context).push<CompanyNote>(
      MaterialPageRoute(
        builder: (_) => CompanyNoteDetailScreen(
          initial: emptyNote,
          companies: _companies,
          sessions: _sessions,
          companyRoles: companyRoles,
          isNew: true,
        ),
      ),
    );
    if (created == null) return;
    final next = <CompanyNote>[created, ..._companies]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _saveCompanies(next);
  }

  Future<void> _addSession(Map<String, String> companyRoles, {CompanyNote? company}) async {
    final created = await Navigator.of(context).push<InterviewSession>(
      MaterialPageRoute(
        builder: (context) => _InterviewSessionEditorSheet(
          companies: _companies,
          initial: null,
          presetCompany: company,
          companyRoles: companyRoles,
        ),
      ),
    );
    if (created == null) return;
    final next = <InterviewSession>[created, ..._sessions]..sort((a, b) => b.heldAt.compareTo(a.heldAt));
    await _saveSessions(next);
  }

  Future<void> _openCompany(CompanyNote note) async {
    final appState = AppStateScope.of(context);
    final companyRoles = <String, String>{};
    final sortedDeadlines = appState.deadlines.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final d in sortedDeadlines) {
      if (d.companyName.trim().isNotEmpty) {
        companyRoles[d.companyName.trim()] = d.jobTitle;
      }
    }

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CompanyNoteDetailScreen(
          initial: note,
          companies: _companies,
          sessions: _sessions,
          companyRoles: companyRoles,
        ),
      ),
    );
    if (result == null) return;
    if (result == 'delete') {
      final next = _companies.where((c) => c.id != note.id).toList(growable: false);
      await _saveCompanies(next);
      return;
    }
    if (result is CompanyNote) {
      final nextCompanies = _companies.map((c) => c.id == result.id ? result : c).toList(growable: false);
      await _saveCompanies(nextCompanies);
    }
  }

  Future<void> _openSession(InterviewSession session) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InterviewSessionDetailScreen(
          initial: session,
          companies: _companies,
        ),
      ),
    );
    if (result == null) return;
    if (result == 'delete') {
      final next = _sessions.where((s) => s.id != session.id).toList(growable: false);
      await _saveSessions(next);
      return;
    }
    if (result is InterviewSession) {
      final nextSessions = _sessions.map((s) => s.id == result.id ? result : s).toList(growable: false);
      await _saveSessions(nextSessions);
    }
  }

  Future<void> _deleteCompany(CompanyNote note) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteDeleteCompanyTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(l10n.noteDeleteConfirm(note.companyName, l10n.noteTypeNote)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final next = _companies.where((c) => c.id != note.id).toList(growable: false);
      await _saveCompanies(next);
    }
  }

  Future<void> _deleteSession(InterviewSession session) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteDeleteInterviewTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(l10n.noteDeleteConfirm('${session.companyName} (${session.round.localizedLabel(l10n)})', l10n.noteTypeReview)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final next = _sessions.where((s) => s.id != session.id).toList(growable: false);
      await _saveSessions(next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);
    
    // 회사명 -> 최신 직무 매핑 생성
    final companyRoles = <String, String>{};
    // 날짜순 정렬하여 나중의 직무가 덮어씌워지도록 함 (최신 직무 반영)
    final sortedDeadlines = appState.deadlines.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    for (final d in sortedDeadlines) {
      if (d.companyName.trim().isNotEmpty) {
        companyRoles[d.companyName.trim()] = d.jobTitle;
      }
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _MainHeader(
              title: l10n.noteTitle,
            ),
            TabBar(
              controller: _tabController,
              isScrollable: false,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
              unselectedLabelStyle: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: l10n.noteTabCompany),
                Tab(text: l10n.noteTabInterview),
              ],
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _CompanyList(
                          companies: _companies,
                          onTapCompany: _openCompany,
                          onLongPressCompany: _deleteCompany,
                        ),
                        _SessionList(
                          sessions: _sessions,
                          onTapSession: _openSession,
                          onLongPressSession: _deleteSession,
                          colorScheme: cs,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loading
            ? null
            : () {
                if (_tabController.index == 0) {
                  _addCompany(companyRoles);
                } else {
                  _addSession(companyRoles);
                }
              },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MainHeader extends StatelessWidget {
  const _MainHeader({
    required this.title,
    this.primaryAction,
    this.secondaryAction,
    this.onBack,
  });

  final String title;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: SizedBox(
        height: 32,
        child: Row(
          children: [
            // Left: Back button (if provided) or Profile & Title
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
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
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
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

            // Right: Actions
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (primaryAction != null || secondaryAction != null) ...[
                    if (primaryAction != null) primaryAction!,
                    if (primaryAction != null && secondaryAction != null) const SizedBox(width: 8),
                    if (secondaryAction != null) secondaryAction!,
                  ] else
                    const SizedBox(width: 24 * 3 + 8 * 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompanyList extends StatelessWidget {
  const _CompanyList({
    required this.companies,
    required this.onTapCompany,
    required this.onLongPressCompany,
  });

  final List<CompanyNote> companies;
  final ValueChanged<CompanyNote> onTapCompany;
  final ValueChanged<CompanyNote> onLongPressCompany;

  @override
  Widget build(BuildContext context) {
    if (companies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context)!.noteEmptyCompany,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: companies.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = companies[index];
        final cs = Theme.of(context).colorScheme;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onTapCompany(c),
              onLongPress: () => onLongPressCompany(c),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        c.companyName.isNotEmpty ? c.companyName[0] : '?',
                        style: TextStyle(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.companyName.isEmpty ? AppLocalizations.of(context)!.noteNoCompanyName : c.companyName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                          if (c.role.trim().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              c.role,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: cs.onSurfaceVariant.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SessionList extends StatelessWidget {
  const _SessionList({
    required this.sessions,
    required this.onTapSession,
    required this.onLongPressSession,
    required this.colorScheme,
  });

  final List<InterviewSession> sessions;
  final ValueChanged<InterviewSession> onTapSession;
  final ValueChanged<InterviewSession> onLongPressSession;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalizations.of(context)!.noteEmptyInterview,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = sessions[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onTapSession(s),
              onLongPress: () => onLongPressSession(s),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        s.round.localizedLabel(AppLocalizations.of(context)!),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.companyName.isEmpty ? AppLocalizations.of(context)!.noteNoCompanyName : s.companyName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 17),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.heldAt.year}.${s.heldAt.month.toString().padLeft(2, '0')}.${s.heldAt.day.toString().padLeft(2, '0')} · ${AppLocalizations.of(context)!.noteQuestionCount(s.questions.length)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CompanyNoteEditorSheet extends StatefulWidget {
  const _CompanyNoteEditorSheet({
    required this.initial,
    required this.companyRoles,
  });

  final CompanyNote? initial;
  final Map<String, String> companyRoles;

  @override
  State<_CompanyNoteEditorSheet> createState() => _CompanyNoteEditorSheetState();
}

class _CompanyNoteEditorSheetState extends State<_CompanyNoteEditorSheet> {
  late final TextEditingController _companyController;
  late final TextEditingController _roleController;
  late final TextEditingController _keywordsController;
  late final TextEditingController _pitchController;
  late final TextEditingController _risksController;
  late final TextEditingController _summaryController;
  late final TextEditingController _fitController;
  late final FocusNode _companyFocusNode;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _companyController = TextEditingController(text: i?.companyName ?? '');
    _roleController = TextEditingController(text: i?.role ?? '');
    _keywordsController = TextEditingController(text: (i?.keywords ?? const <String>[]).join(', '));
    _pitchController = TextEditingController(text: i?.pitch ?? '');
    _risksController = TextEditingController(text: (i?.risks ?? const <String>[]).join(', '));
    _summaryController = TextEditingController(text: i?.summary ?? '');
    _fitController = TextEditingController(text: i?.fit ?? '');
    _companyFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _keywordsController.dispose();
    _pitchController.dispose();
    _risksController.dispose();
    _summaryController.dispose();
    _fitController.dispose();
    _companyFocusNode.dispose();
    super.dispose();
  }

  List<String> _splitCsv(String v) {
    return v
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _launchSearch(String url, String name) async {
    final uri = Uri.parse(url);
    final homeUrl = '${uri.scheme}://${uri.host}';
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobBrowserScreen(
          initialUrl: url,
          homeUrl: homeUrl,
          title: name,
        ),
      ),
    );
  }

  Widget _buildExternalLinkButton(String label, String url, Color color, IconData icon) {
    final isEnabled = _companyController.text.trim().isNotEmpty;
    final displayColor = isEnabled ? color : Colors.grey.withOpacity(0.5);
    final appState = AppStateScope.of(context);

    return Expanded(
      child: InkWell(
        onTap: isEnabled
            ? () {
                final lastUrl = appState.lastVisitedUrls[label];
                _launchSearch(lastUrl ?? url, label);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: displayColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: displayColor.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: displayColor, size: 22),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: displayColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
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
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final initial = widget.initial;
    final suggestions = widget.companyRoles.keys.toList()..sort();
    final l10n = AppLocalizations.of(context)!;

    const fieldSpacing = 12.0;
    const borderRadius = 8.0;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14.0);

    InputDecoration compactDecoration(String label, {String? hintText, Widget? suffixIcon}) {
      final cs = Theme.of(context).colorScheme;
      return InputDecoration(
        labelText: label,
        hintText: hintText,
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        labelStyle: TextStyle(
          fontSize: 13.0, 
          color: cs.primary, 
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintStyle: TextStyle(
          color: cs.onSurfaceVariant.withOpacity(0.35), 
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottom + safeBottom),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          // controller removed – _CompanyNoteEditorSheet has no scrollController
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        initial == null ? l10n.noteAddCompany : l10n.noteEditCompany,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900, 
                          fontSize: 22,
                          letterSpacing: -0.8,
                        ),
                      ),
                    ),
                  ),
                  Material(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.of(context).pop(),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.close, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SizedBox(
                    height: 48,
                    child: DropdownMenu<String>(
                      key: const ValueKey('company_dropdown'),
                      width: constraints.maxWidth,
                      controller: _companyController,
                      label: Text(l10n.noteCompanyName),
                      enableFilter: true,
                      requestFocusOnTap: true,
                      textStyle: textStyle?.copyWith(fontWeight: FontWeight.w600),
                      dropdownMenuEntries: suggestions
                          .map((s) => DropdownMenuEntry<String>(value: s, label: s))
                          .toList(growable: false),
                      inputDecorationTheme: InputDecorationTheme(
                        isDense: true,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                        constraints: const BoxConstraints.tightFor(height: 48),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 13.0, 
                          color: Theme.of(context).colorScheme.primary, 
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      onSelected: (value) {
                        if (value != null) {
                          _companyController.text = value;
                          final role = widget.companyRoles[value];
                          if (role != null && role.isNotEmpty) {
                            _roleController.text = role;
                          }
                        }
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: fieldSpacing),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _roleController,
                  textInputAction: TextInputAction.next,
                  style: textStyle?.copyWith(fontWeight: FontWeight.w600),
                  decoration: compactDecoration(
                    l10n.noteRoleLabel, 
                    hintText: l10n.noteRoleHint,
                    suffixIcon: _roleController.text.isNotEmpty 
                      ? IconButton(
                          onPressed: () => setState(() => _roleController.clear()),
                          icon: const Icon(Icons.cancel, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        )
                      : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              
              // Explore Company Info Section
              const SizedBox(height: 12),
              Text(l10n.noteInfoSearch, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final link in _getSearchLinks(context, _companyController.text.trim())) ...[
                    _buildExternalLinkButton(link.label, link.url, link.color, link.icon),
                    const SizedBox(width: 8),
                  ],
                ],
              ),

              const SizedBox(height: fieldSpacing),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _keywordsController,
                  textInputAction: TextInputAction.next,
                  style: textStyle?.copyWith(fontWeight: FontWeight.w600),
                  decoration: compactDecoration(l10n.noteKeywordsLabel, hintText: l10n.noteKeywordsHint),
                ),
              ),
              const SizedBox(height: fieldSpacing),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _pitchController,
                  style: textStyle?.copyWith(fontWeight: FontWeight.w600),
                  decoration: compactDecoration(l10n.notePitchLabel, hintText: l10n.notePitchHint),
                ),
              ),
              const SizedBox(height: fieldSpacing),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _risksController,
                  style: textStyle?.copyWith(fontWeight: FontWeight.w600),
                  decoration: compactDecoration(l10n.noteRisksLabel, hintText: l10n.noteRisksHint),
                ),
              ),
              const SizedBox(height: 24),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                  onPressed: () {
                    final companyName = _companyController.text.trim();
                    if (companyName.isEmpty) return;
                    final now = DateTime.now();
                    final note = CompanyNote(
                      id: initial?.id ?? '${now.microsecondsSinceEpoch}',
                      companyName: companyName,
                      role: _roleController.text.trim(),
                      keywords: _splitCsv(_keywordsController.text),
                      pitch: _pitchController.text.trim(),
                      risks: _splitCsv(_risksController.text),
                      summary: _summaryController.text.trim(),
                      fit: _fitController.text.trim(),
                      newsSummary: '',
                      businessDirection: '',
                      jobConnection: '',
                      riskPoints: '',
                      expectedQuestions: '',
                      stories: initial?.stories ?? const <CompanyStory>[],
                      questionBank: initial?.questionBank ?? const <String>[],
                      updatedAt: now,
                    );
                    Navigator.of(context).pop(note);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(l10n.save, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterviewSessionEditorSheet extends StatefulWidget {
  const _InterviewSessionEditorSheet({
    required this.companies,
    required this.initial,
    required this.presetCompany,
    required this.companyRoles,
  });

  final List<CompanyNote> companies;
  final InterviewSession? initial;
  final CompanyNote? presetCompany;
  final Map<String, String> companyRoles;

  @override
  State<_InterviewSessionEditorSheet> createState() => _InterviewSessionEditorSheetState();
}

class _InterviewSessionEditorSheetState extends State<_InterviewSessionEditorSheet> {
  static const _pitfallKeys = <String>[
    'pitfallMissingConcept',
    'pitfallVagueLogic',
    'pitfallLackOfExamples',
    'pitfallNoMetrics',
    'pitfallTooWordy',
    'pitfallUnclearPoint',
  ];

  late final TextEditingController _companyController;
  late final TextEditingController _roleController;
  late final FocusNode _companyFocusNode;
  InterviewRound _round = InterviewRound.unknown;
  DateTime _heldAt = DateTime.now();
  String? _companyId;

  // 질문 기록 관련 필드
  late final TextEditingController _questionController;
  late final TextEditingController _intentController;
  late final TextEditingController _answerAtTheTimeController;
  late final TextEditingController _improved60Controller;
  late final TextEditingController _improved120Controller;
  late final TextEditingController _nextActionController;
  late Set<String> _pitfalls;
  ReviewState _reviewState = ReviewState.needsReview;
  int _feeling = 3; // 1-5
  bool _showAdvanced = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  TextEditingController? _activeSttController;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    final preset = widget.presetCompany;
    _companyController = TextEditingController(text: preset?.companyName ?? i?.companyName ?? '');
    _companyController.addListener(() {
      if (mounted) {
        final text = _companyController.text.trim();
        // 직접 입력 중에도 목록에 있는 이름과 일치하면 직무 자동 연동
        if (_roleController.text.trim().isEmpty) {
          final matchedRole = widget.companyRoles[text];
          if (matchedRole != null && matchedRole.isNotEmpty) {
            _roleController.text = matchedRole;
          } else {
            final matchedCompany = widget.companies.where((c) => c.companyName == text).toList();
            if (matchedCompany.isNotEmpty) {
              _roleController.text = matchedCompany.first.role;
            }
          }
        }
        setState(() {});
      }
    });
    _roleController = TextEditingController(text: preset?.role ?? i?.role ?? '');
    _round = i?.round ?? InterviewRound.unknown;
    _heldAt = i?.heldAt ?? DateTime.now();
    _companyId = preset?.id ?? i?.companyId;
    _companyFocusNode = FocusNode();

    // 질문 기록 초기화 (신규 추가 시에는 빈값, 기존 편집 시에는 첫 번째 질문이 있으면 불러오거나 빈값)
    // 하지만 사용자는 '추가' 화면에서 첫 번째 질문을 바로 입력하고 싶어함.
    _questionController = TextEditingController();
    _intentController = TextEditingController();
    _answerAtTheTimeController = TextEditingController();
    _improved60Controller = TextEditingController();
    _improved120Controller = TextEditingController();
    _nextActionController = TextEditingController();
    _pitfalls = {};
    _reviewState = ReviewState.needsReview;
    _initSpeech();
  }

  void _initSpeech() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) {
          debugPrint('STT Error: ${val.errorMsg}');
          if (mounted) {
            setState(() {
              _speechEnabled = false;
              _activeSttController = null;
            });
            String message = l10n.sttError;
            if (val.errorMsg == 'error_permission') {
              message = l10n.micPermissionDenied;
            } else if (val.errorMsg == 'error_speech_timeout') {
              message = l10n.sttTimeout;
            } else if (val.errorMsg == 'error_no_match') {
              message = l10n.sttNoMatch;
            } else if (val.errorMsg == 'error_network') {
              message = l10n.sttNetworkError;
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        onStatus: (val) {
          debugPrint('STT Status: $val');
          if (mounted) setState(() {});
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('STT Init failed: $e');
    }
  }

  void _toggleListening(TextEditingController controller) async {
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }

    if (_speechToText.isListening && _activeSttController == controller) {
      await _speechToText.stop();
      setState(() => _activeSttController = null);
      return;
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    _activeSttController = controller;
    _lastWords = '';
    
    try {
      final locales = await _speechToText.locales();
      final currentLocale = Localizations.localeOf(context);
      final langCode = currentLocale.languageCode;
      
      // 현재 앱 언어에 맞는 STT 로케일 찾기
      String? targetLocaleId;
      
      if (langCode == 'ko') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'ko_KR' || l.localeId.startsWith('ko'), orElse: () => locales.first).localeId;
      } else if (langCode == 'en') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'en_US' || l.localeId.startsWith('en'), orElse: () => locales.first).localeId;
      } else if (langCode == 'ja') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'ja_JP' || l.localeId.startsWith('ja'), orElse: () => locales.first).localeId;
      } else if (langCode == 'zh') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'zh_CN' || l.localeId == 'zh_TW' || l.localeId.startsWith('zh'), orElse: () => locales.first).localeId;
      } else if (langCode == 'hi') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'hi_IN' || l.localeId.startsWith('hi'), orElse: () => locales.first).localeId;
      }

      await _speechToText.listen(
        onResult: (result) {
          if (mounted && _activeSttController == controller) {
            setState(() {
              _lastWords = result.recognizedWords;
              if (result.finalResult) {
                final currentText = controller.text;
                final newText = _lastWords;
                if (currentText.isEmpty) {
                  controller.text = newText;
                } else {
                  final suffix = (currentText.endsWith(' ') || currentText.endsWith('\n')) ? '' : ' ';
                  controller.text = '$currentText$suffix$newText';
                }
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
                _lastWords = '';
                _activeSttController = null;
              }
            });
          }
        },
        localeId: targetLocaleId,
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('STT Listen failed: $e');
      _activeSttController = null;
    }
    if (mounted) setState(() {});
  }

  Future<void> _launchSearch(String url, String name) async {
    final uri = Uri.parse(url);
    final homeUrl = '${uri.scheme}://${uri.host}';
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobBrowserScreen(
          initialUrl: url,
          homeUrl: homeUrl,
          title: name,
        ),
      ),
    );
  }

  String _getPitfallLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'pitfallMissingConcept':
        return l10n.pitfallMissingConcept;
      case 'pitfallVagueLogic':
        return l10n.pitfallVagueLogic;
      case 'pitfallLackOfExamples':
        return l10n.pitfallLackOfExamples;
      case 'pitfallNoMetrics':
        return l10n.pitfallNoMetrics;
      case 'pitfallTooWordy':
        return l10n.pitfallTooWordy;
      case 'pitfallUnclearPoint':
        return l10n.pitfallUnclearPoint;
      default:
        return key;
    }
  }

  Widget _buildExternalLinkButton(String name, String url, Color color, IconData icon) {
    final isEnabled = _companyController.text.trim().isNotEmpty;
    final displayColor = isEnabled ? color : Colors.grey.withOpacity(0.5);
    final appState = AppStateScope.of(context);

    return Expanded(
      child: InkWell(
        onTap: isEnabled
            ? () {
                final lastUrl = appState.lastVisitedUrls[name];
                _launchSearch(lastUrl ?? url, name);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: displayColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: displayColor.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: displayColor, size: 22),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: displayColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
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
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _companyFocusNode.dispose();
    _questionController.dispose();
    _intentController.dispose();
    _answerAtTheTimeController.dispose();
    _improved60Controller.dispose();
    _improved120Controller.dispose();
    _nextActionController.dispose();
    super.dispose();
  }

  Widget _buildFeelingButton(int score, String label, Color color) {
    final isSelected = _feeling == score;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => setState(() => _feeling = score),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getFeelingEmoji(score),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFeelingEmoji(int score) {
    switch (score) {
      case 1: return '😫';
      case 2: return '😟';
      case 3: return '😐';
      case 4: return '🤔';
      case 5: return '😎';
      default: return '😐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final initial = widget.initial;
    final l10n = AppLocalizations.of(context)!;

    // Autocomplete 후보군 생성 (기업 노트 이름 + 일정 이름)
    final allNames = {
      ...widget.companies.map((c) => c.companyName),
      ...widget.companyRoles.keys,
    }.toList()..sort();

    const fieldSpacing = 12.0;
    const borderRadius = 8.0;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14.0);

    InputDecoration compactDecoration(String label, {String? hintText, Widget? suffixIcon}) {
      final cs = Theme.of(context).colorScheme;
      return InputDecoration(
        labelText: label,
        hintText: hintText,
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        labelStyle: TextStyle(
          fontSize: 13.0, 
          color: cs.primary, 
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintStyle: TextStyle(
          color: cs.onSurfaceVariant.withOpacity(0.35), 
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    final appState = AppStateScope.of(context);
    final selectedCompanyName = _companyController.text.trim();
    final companyDeadlines = appState.deadlines
        .where((d) => 
            d.companyName == selectedCompanyName && 
            d.status.isInterviewGroup && 
            d.status != JobStatus.videoInterview // 인적성검사 제외
        )
        .toList()
      ..sort((a, b) => a.deadlineAt.compareTo(b.deadlineAt));

    final hasDeadlines = companyDeadlines.isNotEmpty;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          initial == null ? l10n.noteAddInterview : l10n.noteEditInterview,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 12, 20, 24 + bottom + safeBottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SizedBox(
                  height: 48,
                  child: DropdownMenu<String>(
                    key: const ValueKey('session_company_dropdown'),
                    width: constraints.maxWidth,
                    controller: _companyController,
                    label: Text(l10n.noteCompanyName),
                    enableFilter: true,
                    requestFocusOnTap: true,
                    textStyle: textStyle?.copyWith(fontWeight: FontWeight.w600),
                    dropdownMenuEntries: allNames
                        .map((s) => DropdownMenuEntry<String>(value: s, label: s))
                        .toList(growable: false),
                    inputDecorationTheme: InputDecorationTheme(
                      isDense: true,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                      constraints: const BoxConstraints.tightFor(height: 48),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      suffixIconColor: Theme.of(context).colorScheme.primary,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 13.0, 
                        color: Theme.of(context).colorScheme.primary, 
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    onSelected: (option) {
                      if (option == null) return;
                      _companyController.text = option;
                      
                      final matched = widget.companies.where((c) => c.companyName == option).toList();
                      if (matched.isNotEmpty) {
                        final c = matched.first;
                        setState(() => _companyId = c.id);
                        if (_roleController.text.trim().isEmpty) {
                          _roleController.text = c.role;
                        }
                      } else {
                        setState(() => _companyId = null);
                        final role = widget.companyRoles[option];
                        if (role != null && role.isNotEmpty) {
                           _roleController.text = role;
                        }
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: fieldSpacing),
            SizedBox(
              height: 48,
              child: TextField(
                controller: _roleController,
                textInputAction: TextInputAction.next,
                style: textStyle?.copyWith(fontWeight: FontWeight.w600),
                decoration: compactDecoration(
                  l10n.noteRoleLabel, 
                  hintText: l10n.noteRoleHint,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_roleController.text.isNotEmpty)
                        IconButton(
                          onPressed: () => setState(() => _roleController.clear()),
                          icon: const Icon(Icons.cancel, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      IconButton(
                        icon: Icon(
                          (_speechToText.isListening && _activeSttController == _roleController) ? Icons.stop : Icons.mic,
                          color: (_speechToText.isListening && _activeSttController == _roleController) ? Colors.red : Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        onPressed: () => _toggleListening(_roleController),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_speechToText.isListening && _activeSttController == _roleController && _lastWords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  l10n.recognizingText(_lastWords),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                ),
              ),
            
            const SizedBox(height: 24),
            Text(l10n.companySearchTitle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final link in _getSearchLinks(context, _companyController.text.trim())) ...[
                  _buildExternalLinkButton(link.label, link.url, link.color, link.icon),
                  const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: fieldSpacing),

            const SizedBox(height: 24),
            Text(l10n.noteRoundLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                if (hasDeadlines) {
                  return SizedBox(
                    height: 48,
                    child: DropdownMenu<JobDeadline?>(
                      width: constraints.maxWidth,
                      initialSelection: null,
                      label: Text(l10n.noteRoundLabel),
                      textStyle: textStyle?.copyWith(fontWeight: FontWeight.w600),
                      dropdownMenuEntries: [
                        ...companyDeadlines.map((d) {
                          final label = '${d.status.localizedLabel(l10n)} (${DateFormatters.ymd.format(d.deadlineAt)})';
                          return DropdownMenuEntry<JobDeadline?>(
                            value: d,
                            label: label,
                            style: MenuItemButton.styleFrom(
                              textStyle: textStyle?.copyWith(fontWeight: FontWeight.w500),
                            ),
                          );
                        }),
                        DropdownMenuEntry<JobDeadline?>(
                          value: null,
                          label: l10n.deadlineUnknown,
                          style: MenuItemButton.styleFrom(
                            textStyle: textStyle?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                      inputDecorationTheme: InputDecorationTheme(
                        isDense: true,
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                        constraints: const BoxConstraints.tightFor(height: 48),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(borderRadius),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                        ),
                        labelStyle: TextStyle(
                          fontSize: 13.0, 
                          color: Theme.of(context).colorScheme.primary, 
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      onSelected: (d) {
                        if (d != null) {
                          setState(() {
                            // JobStatus를 InterviewRound로 변환 시도
                            if (d.status == JobStatus.document) _round = InterviewRound.screening;
                            else if (d.status == JobStatus.interview1) _round = InterviewRound.first;
                            else if (d.status == JobStatus.interview2) _round = InterviewRound.second;
                            else if (d.status == JobStatus.finalInterview) _round = InterviewRound.finalRound;
                            _heldAt = DateTime(d.deadlineAt.year, d.deadlineAt.month, d.deadlineAt.day);
                          });
                        } else {
                          setState(() {
                            _round = InterviewRound.unknown;
                          });
                        }
                      },
                    ),
                  );
                }

                return SizedBox(
                  height: 48,
                  child: DropdownMenu<InterviewRound>(
                    width: constraints.maxWidth,
                    initialSelection: _round,
                    label: Text(l10n.noteRoundLabel),
                    textStyle: textStyle?.copyWith(fontWeight: FontWeight.w600),
                    dropdownMenuEntries: InterviewRound.values
                        .where((r) => r != InterviewRound.unknown)
                        .map((r) => DropdownMenuEntry<InterviewRound>(
                              value: r,
                              label: r.localizedLabel(l10n),
                              style: MenuItemButton.styleFrom(
                                textStyle: textStyle?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            ))
                        .toList(growable: false),
                    inputDecorationTheme: InputDecorationTheme(
                      isDense: true,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
                      constraints: const BoxConstraints.tightFor(height: 48),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(borderRadius),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                      ),
                      labelStyle: TextStyle(
                        fontSize: 13.0, 
                        color: Theme.of(context).colorScheme.primary, 
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                    ),
                    onSelected: (v) => setState(() => _round = v ?? InterviewRound.unknown),
                  ),
                );
              },
            ),
            const SizedBox(height: fieldSpacing),
            SizedBox(
              height: 48,
              child: InkWell(
                borderRadius: BorderRadius.circular(borderRadius),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _heldAt,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked == null) return;
                  setState(() => _heldAt = DateTime(picked.year, picked.month, picked.day));
                },
                child: InputDecorator(
                  decoration: compactDecoration(
                    l10n.noteDateLabel, 
                    suffixIcon: Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
                  ),
                  child: Text(
                    '${_heldAt.year}.${_heldAt.month.toString().padLeft(2, '0')}.${_heldAt.day.toString().padLeft(2, '0')}',
                    style: textStyle?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    l10n.noteQuestionRecord,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900, fontSize: 18),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                  icon: Icon(_showAdvanced ? Icons.expand_less : Icons.auto_awesome, size: 18),
                  label: Text(_showAdvanced ? l10n.viewSimple : l10n.viewAdvanced, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: _showAdvanced ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              minLines: 1,
              maxLines: 5,
              decoration: compactDecoration(
                l10n.noteQuestionLabel,
                hintText: l10n.noteQuestionHint,
                suffixIcon: IconButton(
                  icon: Icon(
                    (_speechToText.isListening && _activeSttController == _questionController) ? Icons.stop : Icons.mic,
                    color: (_speechToText.isListening && _activeSttController == _questionController) ? Colors.red : Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _toggleListening(_questionController),
                ),
              ),
            ),
            if (_speechToText.isListening && _activeSttController == _questionController && _lastWords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  l10n.recognizingText(_lastWords),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerAtTheTimeController,
              minLines: 3,
              maxLines: 10,
              decoration: compactDecoration(
                l10n.noteAnswerAtTheTime,
                hintText: l10n.inputAnswerHint,
                suffixIcon: IconButton(
                  icon: Icon(
                    (_speechToText.isListening && _activeSttController == _answerAtTheTimeController) ? Icons.stop : Icons.mic,
                    color: (_speechToText.isListening && _activeSttController == _answerAtTheTimeController) ? Colors.red : Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _toggleListening(_answerAtTheTimeController),
                ),
              ),
            ),
            if (_speechToText.isListening && _activeSttController == _answerAtTheTimeController && _lastWords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                child: Text(
                  l10n.recognizingText(_lastWords),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // 자가 점수 (Feeling) 섹션
            Text(
              l10n.feelingScore,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFeelingButton(1, l10n.feelingBad, Colors.red),
                  _buildFeelingButton(2, l10n.feelingDisappointed, Colors.orange),
                  _buildFeelingButton(3, l10n.feelingNormal, Colors.blueGrey),
                  _buildFeelingButton(4, l10n.feelingAmbiguous, Colors.blue),
                  _buildFeelingButton(5, l10n.feelingGood, Colors.green),
                ],
              ),
            ),
            
            if (_showAdvanced) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(l10n.advancedRecordTitle, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _intentController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: compactDecoration(
                        l10n.noteIntent,
                        hintText: l10n.noteIntentHint,
                        suffixIcon: IconButton(
                          icon: Icon(
                            (_speechToText.isListening && _activeSttController == _intentController) ? Icons.stop : Icons.mic,
                            color: (_speechToText.isListening && _activeSttController == _intentController) ? Colors.red : Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _toggleListening(_intentController),
                        ),
                      ),
                    ),
                    if (_speechToText.isListening && _activeSttController == _intentController && _lastWords.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          l10n.recognizingText(_lastWords),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _improved60Controller,
                      minLines: 2,
                      maxLines: 5,
                      decoration: compactDecoration(
                        l10n.noteImproved60,
                        hintText: l10n.noteImproved60Hint,
                        suffixIcon: IconButton(
                          icon: Icon(
                            (_speechToText.isListening && _activeSttController == _improved60Controller) ? Icons.stop : Icons.mic,
                            color: (_speechToText.isListening && _activeSttController == _improved60Controller) ? Colors.red : Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _toggleListening(_improved60Controller),
                        ),
                      ),
                    ),
                    if (_speechToText.isListening && _activeSttController == _improved60Controller && _lastWords.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          l10n.recognizingText(_lastWords),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _improved120Controller,
                      minLines: 2,
                      maxLines: 6,
                      decoration: compactDecoration(
                        l10n.noteImproved120,
                        hintText: l10n.noteImproved120Hint,
                        suffixIcon: IconButton(
                          icon: Icon(
                            (_speechToText.isListening && _activeSttController == _improved120Controller) ? Icons.stop : Icons.mic,
                            color: (_speechToText.isListening && _activeSttController == _improved120Controller) ? Colors.red : Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _toggleListening(_improved120Controller),
                        ),
                      ),
                    ),
                    if (_speechToText.isListening && _activeSttController == _improved120Controller && _lastWords.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          l10n.recognizingText(_lastWords),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(l10n.notePitfalls, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _pitfallKeys.map((key) {
                        final label = _getPitfallLabel(key, l10n);
                        final selected = _pitfalls.contains(label);
                        return FilterChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (v) => setState(() {
                            if (v) {
                              _pitfalls.add(label);
                            } else {
                              _pitfalls.remove(label);
                            }
                          }),
                          side: BorderSide.none,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          selectedColor: Theme.of(context).colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: selected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12,
                          ),
                        );
                      }).toList(growable: false),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nextActionController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: compactDecoration(
                        l10n.noteNextActionLabel,
                        hintText: l10n.noteNextActionHint,
                        suffixIcon: IconButton(
                          icon: Icon(
                            (_speechToText.isListening && _activeSttController == _nextActionController) ? Icons.stop : Icons.mic,
                            color: (_speechToText.isListening && _activeSttController == _nextActionController) ? Colors.red : Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => _toggleListening(_nextActionController),
                        ),
                      ),
                    ),
                    if (_speechToText.isListening && _activeSttController == _nextActionController && _lastWords.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text(
                          l10n.recognizingText(_lastWords),
                          style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            DropdownButtonFormField<ReviewState>(
              key: ValueKey(_reviewState),
              value: _reviewState,
              decoration: compactDecoration(l10n.noteReviewStatus).copyWith(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              items: ReviewState.values.map((s) => DropdownMenuItem(
                value: s,
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 16,
                      color: s == ReviewState.needsReview ? Colors.amber : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Text(s.localizedLabel(l10n), style: const TextStyle(fontSize: 15)),
                  ],
                ),
              )).toList(growable: false),
              onChanged: (v) => setState(() => _reviewState = v ?? ReviewState.needsReview),
              icon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
              dropdownColor: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              menuMaxHeight: 300,
              isExpanded: true,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: () {
                  final companyName = _companyController.text.trim();
                  if (companyName.isEmpty) return;
                  
                  final now = DateTime.now();
                  final List<QuestionNote> questions = initial?.questions != null 
                      ? List.from(initial!.questions) 
                      : <QuestionNote>[];

                  // 질문 입력 필드가 비어있지 않으면 새로운 질문 추가
                  final questionText = _questionController.text.trim();
                  if (questionText.isNotEmpty) {
                    final nextReviewAt = (_reviewState == ReviewState.needsReview) 
                        ? now.add(const Duration(days: 3)) 
                        : null;
                    final newQuestion = QuestionNote(
                      id: '${now.microsecondsSinceEpoch}',
                      question: questionText,
                      intent: _intentController.text.trim(),
                      answerAtTheTime: _answerAtTheTimeController.text.trim(),
                      improved60: _improved60Controller.text.trim(),
                      improved120: _improved120Controller.text.trim(),
                      pitfalls: _pitfalls.toList(),
                      nextAction: _nextActionController.text.trim(),
                      reviewState: _reviewState,
                      nextReviewAt: nextReviewAt,
                      feeling: _feeling,
                    );
                    questions.insert(0, newQuestion);
                  }

                  final session = InterviewSession(
                    id: initial?.id ?? '${now.microsecondsSinceEpoch}',
                    companyId: _companyId,
                    companyName: companyName,
                    role: _roleController.text.trim(),
                    round: _round,
                    heldAt: _heldAt,
                    questions: questions,
                    updatedAt: now,
                  );
                  Navigator.of(context).pop(session);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(l10n.save, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CompanyNoteDetailScreen extends StatefulWidget {
  const CompanyNoteDetailScreen({
    super.key,
    required this.initial,
    required this.companies,
    required this.sessions,
    required this.companyRoles,
    this.isNew = false,
  });

  final CompanyNote initial;
  final List<CompanyNote> companies;
  final List<InterviewSession> sessions;
  final Map<String, String> companyRoles;
  final bool isNew;

  @override
  State<CompanyNoteDetailScreen> createState() => _CompanyNoteDetailScreenState();
}

class _CompanyNoteDetailScreenState extends State<CompanyNoteDetailScreen> {
  late CompanyNote _note;
  late final TextEditingController _companyController;
  late final TextEditingController _roleController;
  late final TextEditingController _keywordsController;
  late final TextEditingController _pitchController;
  late final TextEditingController _risksController;
  late final TextEditingController _summaryController;
  late final TextEditingController _fitController;
  late final TextEditingController _newsSummaryController;
  late final TextEditingController _businessDirectionController;
  late final TextEditingController _jobConnectionController;
  late final TextEditingController _riskPointsController;
  late final TextEditingController _expectedQuestionsController;
  bool _isEditing = false;
  List<String> _currentSourceUrls = [];

  @override
  void initState() {
    super.initState();
    _note = widget.initial;
    _isEditing = widget.isNew;
    _currentSourceUrls = _note.sourceUrls;
    _companyController = TextEditingController(text: _note.companyName);
    _companyController.addListener(() {
      if (mounted) {
        final text = _companyController.text.trim();
        // [수정] 기업 목록 최신화 확인 (BuildContext를 통해 AppState 접근)
        final appState = AppStateScope.of(context);
        final companyRolesMap = <String, String>{};
        for (final d in appState.deadlines) {
          if (d.companyName.trim().isNotEmpty) {
            companyRolesMap[d.companyName.trim()] = d.jobTitle;
          }
        }

        // 직접 입력 중에도 목록에 있는 이름과 일치하면 데이터 자동 연동
        if (_isEditing) {
          final matchedCompanies = widget.companies.where((c) => c.companyName == text).toList();
          if (matchedCompanies.isNotEmpty) {
            final matched = matchedCompanies.first;
            // 이미 데이터가 채워져 있지 않은 경우에만 자동 채우기 (사용자 입력 방해 방지)
            if (_roleController.text.trim().isEmpty) _roleController.text = matched.role;
            if (_keywordsController.text.trim().isEmpty) _keywordsController.text = matched.keywords.join(', ');
            if (_pitchController.text.trim().isEmpty) _pitchController.text = matched.pitch;
            if (_risksController.text.trim().isEmpty) _risksController.text = matched.risks.join(', ');
            if (_summaryController.text.trim().isEmpty) _summaryController.text = matched.summary;
            if (_fitController.text.trim().isEmpty) _fitController.text = matched.fit;
            if (_newsSummaryController.text.trim().isEmpty) _newsSummaryController.text = matched.newsSummary;
            if (_businessDirectionController.text.trim().isEmpty) _businessDirectionController.text = matched.businessDirection;
            if (_jobConnectionController.text.trim().isEmpty) _jobConnectionController.text = matched.jobConnection;
            if (_riskPointsController.text.trim().isEmpty) _riskPointsController.text = matched.riskPoints;
            if (_expectedQuestionsController.text.trim().isEmpty) _expectedQuestionsController.text = matched.expectedQuestions;
            if (_currentSourceUrls.isEmpty) _currentSourceUrls = matched.sourceUrls;
          } else {
            // 기업노트에는 없지만 공고에 있는 경우 직무만 연동
            if (_roleController.text.trim().isEmpty) {
              final matchedRole = companyRolesMap[text];
              if (matchedRole != null && matchedRole.isNotEmpty) {
                _roleController.text = matchedRole;
              }
            }
          }
        }
        setState(() {});
      }
    });
    _roleController = TextEditingController(text: _note.role);
    _keywordsController = TextEditingController(text: _note.keywords.join(', '));
    _pitchController = TextEditingController(text: _note.pitch);
    _risksController = TextEditingController(text: _note.risks.join(', '));
    _summaryController = TextEditingController(text: _note.summary);
    _fitController = TextEditingController(text: _note.fit);
    _newsSummaryController = TextEditingController(text: _note.newsSummary);
    _businessDirectionController = TextEditingController(text: _note.businessDirection);
    _jobConnectionController = TextEditingController(text: _note.jobConnection);
    _riskPointsController = TextEditingController(text: _note.riskPoints);
    _expectedQuestionsController = TextEditingController(text: _note.expectedQuestions);
  }

  @override
  void dispose() {
    _companyController.dispose();
    _roleController.dispose();
    _keywordsController.dispose();
    _pitchController.dispose();
    _risksController.dispose();
    _summaryController.dispose();
    _fitController.dispose();
    _newsSummaryController.dispose();
    _businessDirectionController.dispose();
    _jobConnectionController.dispose();
    _riskPointsController.dispose();
    _expectedQuestionsController.dispose();
    super.dispose();
  }

  Future<void> _runAiMatching() async {
    final companyName = _companyController.text.trim();
    if (companyName.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
    
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(l10n.noteAiMatchingRunning),
          ],
        ),
        duration: const Duration(minutes: 1), // Will be hidden manually
      ),
    );

    try {
      final info = await CompanyInfoService.fetchCompanyInfo(companyName);
      
      if (!mounted) return;
      messenger.hideCurrentSnackBar();

      showDialog(
        context: context,
        barrierDismissible: false, // 광고 시청을 유도하기 위해 외부 클릭 닫기 방지
        builder: (context) => AlertDialog(
          title: Text(l10n.noteAiMatching, style: const TextStyle(fontWeight: FontWeight.w900)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.noteAiMatchingSuccess),
              const SizedBox(height: 16),
              Text(l10n.noteAiAnalysisResultReady, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Text(l10n.noteAiAnalysisAdNotice, style: const TextStyle(fontSize: 12)),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(l10n.cancel, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () async {
                      // 다이얼로그 닫기
                      Navigator.pop(context);
                      
                      // 로딩 인디케이터 표시
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(l10n.noteLoadingAd),
                      ),
                    );

                      // 광고 보여주기
                      final rewarded = await RewardedAdService.showAd(
                        onAdDismissed: () {
                          // 광고 닫혔을 때 추가 동작이 필요하면 여기에 작성
                        },
                      );

                      if (!mounted) return;

                      if (rewarded) {
                        // [핵심 수정] 광고 시청 완료 시에만 상태 업데이트
                        setState(() {
                          _summaryController.text = info.summary;
                          _newsSummaryController.text = info.newsSummary;
                          _businessDirectionController.text = info.businessDirection;
                          _jobConnectionController.text = info.jobConnection;
                          _riskPointsController.text = info.riskPoints;
                          if (info.keywords.isNotEmpty) {
                            _keywordsController.text = info.keywords.join(', ');
                          }
                          _currentSourceUrls = info.sourceUrls;
                        });

                        // 결과 다이얼로그 표시
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.noteAiMatching, style: const TextStyle(fontWeight: FontWeight.w900)),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.noteAiMatchingSuccess),
                                const SizedBox(height: 16),
                                Text(l10n.noteLatestNews, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                const SizedBox(height: 8),
                                  ...info.news.map((n) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Expanded(child: _EditableAnalysisCard.buildMarkdownText(
                                          context,
                                          n,
                                          Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
                                          Colors.blue,
                                        )),
                                      ],
                                    ),
                                  )),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text(l10n.ok),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // 광고 시청 실패 또는 취소 시 안내
                      messenger.showSnackBar(
                        SnackBar(content: Text(l10n.noteAdNotCompleted)),
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  label: Text(l10n.noteWatchAdToView, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noteAiMatchingFail)),
      );
    }
  }

  Future<void> _launchSearch(String url, String name) async {
    final uri = Uri.parse(url);
    final homeUrl = '${uri.scheme}://${uri.host}';
    
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => JobBrowserScreen(
          initialUrl: url,
          homeUrl: homeUrl,
          title: name,
        ),
      ),
    );
  }

  Widget _buildExternalLinkButton(String label, String url, Color color, IconData icon) {
    final isEnabled = _companyController.text.trim().isNotEmpty;
    final displayColor = isEnabled ? color : Colors.grey.withOpacity(0.5);
    final appState = AppStateScope.of(context);

    return Expanded(
      child: InkWell(
        onTap: isEnabled
            ? () {
                final lastUrl = appState.lastVisitedUrls[label];
                _launchSearch(lastUrl ?? url, label);
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: displayColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: displayColor.withOpacity(0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: displayColor, size: 22),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    color: displayColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
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
  }

  void _save() {
    final now = DateTime.now();
    final updatedNote = _note.copyWith(
      companyName: _companyController.text.trim(),
      role: _roleController.text.trim(),
      keywords: _keywordsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      pitch: _pitchController.text.trim(),
      risks: _risksController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      summary: _summaryController.text.trim(),
      fit: _fitController.text.trim(),
      newsSummary: _newsSummaryController.text.trim(),
      businessDirection: _businessDirectionController.text.trim(),
      jobConnection: _jobConnectionController.text.trim(),
      riskPoints: _riskPointsController.text.trim(),
      expectedQuestions: _expectedQuestionsController.text.trim(),
      updatedAt: now,
      sourceUrls: _currentSourceUrls,
    );
    
    if (widget.isNew) {
      Navigator.of(context).pop(updatedNote);
    } else {
      setState(() {
        _note = updatedNote;
        _isEditing = false;
      });
    }
  }

  Future<void> _editTop() async {
    setState(() {
      _isEditing = true;
    });
  }

  Future<void> _addStory() async {
    final created = await showModalBottomSheet<CompanyStory>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StoryEditorSheet(initial: null),
    );
    if (created == null) return;
    final now = DateTime.now();
    final next = _note.copyWith(stories: [created, ..._note.stories], updatedAt: now);
    setState(() => _note = next);
  }

  Future<void> _editStory(CompanyStory story) async {
    final updated = await showModalBottomSheet<CompanyStory>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _StoryEditorSheet(initial: story),
    );
    if (updated == null) return;
    final now = DateTime.now();
    final nextStories = _note.stories.map((s) => s.id == updated.id ? updated : s).toList(growable: false);
    setState(() => _note = _note.copyWith(stories: nextStories, updatedAt: now));
  }

  Future<void> _deleteStory(CompanyStory story) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteDeleteEpisodeTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(l10n.noteDeleteConfirm(story.title.isEmpty ? l10n.noteNoTitle : story.title, l10n.noteEpisode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final now = DateTime.now();
      final nextStories = _note.stories.where((s) => s.id != story.id).toList(growable: false);
      setState(() => _note = _note.copyWith(stories: nextStories, updatedAt: now));
    }
  }

  Future<void> _deleteQuestionBankItem(String question) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteDeleteQuestionTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(l10n.noteDeleteConfirm(question, l10n.noteQuestion)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final now = DateTime.now();
      final nextBank = _note.questionBank.where((q) => q != question).toList(growable: false);
      setState(() => _note = _note.copyWith(questionBank: nextBank, updatedAt: now));
    }
  }

  Future<void> _addQuestion() async {
    final added = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _SimpleQuestionEditorSheet(),
    );

    final v = added?.trim() ?? '';
    if (v.isEmpty) return;
    final now = DateTime.now();
    setState(() => _note = _note.copyWith(questionBank: [v, ..._note.questionBank], updatedAt: now));
  }

  Future<void> _deleteCompany() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteDeleteCompanyTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(l10n.noteDeleteConfirm(_note.companyName, l10n.noteTypeNote)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      Navigator.of(context).pop('delete');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    
    final relatedSessions = widget.sessions
        .where((s) => (s.companyId != null && s.companyId == _note.id) || s.companyName.trim() == _note.companyName.trim())
        .toList(growable: false)
      ..sort((a, b) => b.heldAt.compareTo(a.heldAt));

    final appState = AppStateScope.of(context);
    final allCompanyNames = {
      ...widget.companies.map((c) => c.companyName),
      ...widget.companyRoles.keys,
      ...appState.deadlines.map((d) => d.companyName.trim()).where((name) => name.isNotEmpty),
    }.toList()..sort();

    const fieldSpacing = 12.0;
    const borderRadius = 8.0;
    final textStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14.0);

    InputDecoration compactDecoration(String label, {String? hintText, Widget? suffixIcon}) {
      return InputDecoration(
        labelText: label,
        hintText: hintText,
        isDense: true,
        filled: true,
        fillColor: cs.surfaceContainerLowest,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        labelStyle: TextStyle(
          fontSize: 13.0, 
          color: cs.primary, 
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintStyle: TextStyle(
          color: cs.onSurfaceVariant.withOpacity(0.35), 
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _MainHeader(
              title: _isEditing 
                  ? (widget.isNew ? l10n.noteAddCompany : l10n.noteEditCompany)
                  : (_note.companyName.isEmpty ? l10n.noteTypeNote : _note.companyName),
              onBack: () => Navigator.of(context).pop(_note),
              primaryAction: _isEditing
                  ? IconButton(
                      onPressed: _save,
                      icon: const Icon(Icons.check),
                      color: cs.primary,
                    )
                  : IconButton(onPressed: _editTop, icon: const Icon(Icons.edit)),
              secondaryAction: _isEditing
                  ? IconButton(
                      onPressed: () {
                        if (widget.isNew) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() {
                            _isEditing = false;
                            // Reset controllers
                            _companyController.text = _note.companyName;
                            _roleController.text = _note.role;
                            _keywordsController.text = _note.keywords.join(', ');
                            _pitchController.text = _note.pitch;
                            _risksController.text = _note.risks.join(', ');
                            _summaryController.text = _note.summary;
                            _fitController.text = _note.fit;
                            _newsSummaryController.text = _note.newsSummary;
                            _businessDirectionController.text = _note.businessDirection;
                            _jobConnectionController.text = _note.jobConnection;
                            _riskPointsController.text = _note.riskPoints;
                            _expectedQuestionsController.text = _note.expectedQuestions;
                          });
                        }
                      },
                      icon: const Icon(Icons.close),
                    )
                  : IconButton(
                      onPressed: _deleteCompany,
                      icon: const Icon(Icons.delete_outline),
                      color: cs.error,
                      tooltip: l10n.delete,
                    ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  if (_isEditing) ...[
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return SizedBox(
                          height: 48,
                          child: DropdownMenu<String>(
                            width: constraints.maxWidth,
                            controller: _companyController,
                            label: Text(l10n.noteCompanyName),
                            enableFilter: true,
                            requestFocusOnTap: true,
                            textStyle: textStyle?.copyWith(fontWeight: FontWeight.w600),
                            dropdownMenuEntries: allCompanyNames
                                .map((s) => DropdownMenuEntry<String>(value: s, label: s))
                                .toList(growable: false),
                            inputDecorationTheme: InputDecorationTheme(
                              isDense: true,
                              filled: true,
                              fillColor: cs.surfaceContainerLowest,
                              constraints: const BoxConstraints.tightFor(height: 48),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(borderRadius),
                                borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(borderRadius),
                                borderSide: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(borderRadius),
                                borderSide: BorderSide(color: cs.primary, width: 1.5),
                              ),
                              labelStyle: TextStyle(
                                fontSize: 13.0, 
                                color: cs.primary, 
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                            ),
                            onSelected: (selection) {
                              if (selection == null) return;
                              _companyController.text = selection;
                              
                              // [수정] 기업 목록 최신화 확인
                              final appState = AppStateScope.of(context);
                              final companyRolesMap = <String, String>{};
                              for (final d in appState.deadlines) {
                                if (d.companyName.trim().isNotEmpty) {
                                  companyRolesMap[d.companyName.trim()] = d.jobTitle;
                                }
                              }

                              // 기업 목록에서 해당 기업을 찾아 데이터 자동 채우기
                              final matchedCompanies = widget.companies.where((c) => c.companyName == selection).toList();
                              if (matchedCompanies.isNotEmpty) {
                                final matched = matchedCompanies.first;
                                _roleController.text = matched.role;
                                _keywordsController.text = matched.keywords.join(', ');
                                _pitchController.text = matched.pitch;
                                _risksController.text = matched.risks.join(', ');
                                _summaryController.text = matched.summary;
                                _fitController.text = matched.fit;
                                _newsSummaryController.text = matched.newsSummary;
                                _businessDirectionController.text = matched.businessDirection;
                                _jobConnectionController.text = matched.jobConnection;
                                _riskPointsController.text = matched.riskPoints;
                                _expectedQuestionsController.text = matched.expectedQuestions;
                                _currentSourceUrls = matched.sourceUrls;
                              } else {
                                // 기존 로직: 공고 기반 직무 자동 연동
                                final role = companyRolesMap[selection];
                                if (role != null && role.isNotEmpty) {
                                  _roleController.text = role;
                                }
                              }
                              setState(() {}); // UI 업데이트
                            },
              ),
            );
          },
        ),
        const SizedBox(height: fieldSpacing),
        TextField(
          controller: _roleController,
          style: textStyle?.copyWith(fontWeight: FontWeight.w600),
          decoration: compactDecoration(
            l10n.noteRoleLabel,
            hintText: l10n.noteRoleHint,
          ),
        ),

        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(l10n.noteAiAnalysisTitle,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.primary)),
            ),
            TextButton.icon(
              onPressed: _companyController.text.trim().isEmpty ? null : _runAiMatching,
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: Text(l10n.noteAiMatching, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                visualDensity: VisualDensity.compact,
                foregroundColor: cs.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // AI 기업 분석 결과 (읽기 전용 및 클릭 가능)
        _buildEditableAnalysisCard(context, l10n.noteNewsSummaryHeader, _newsSummaryController, cs.primary),
        const SizedBox(height: 20),
        _buildEditableAnalysisCard(context, l10n.noteBusinessDirectionHeader, _businessDirectionController, cs.primary),
        const SizedBox(height: 20),
        _buildEditableAnalysisCard(context, l10n.noteJobConnectionHeader, _jobConnectionController, cs.primary),
        const SizedBox(height: 20),
        _buildEditableAnalysisCard(context, l10n.noteRiskPointsHeader, _riskPointsController, cs.error),
        
        const SizedBox(height: 24),
        Text(l10n.noteUserInputSection,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        Row(
          children: [
            for (final link in _getSearchLinks(context, _companyController.text.trim())) ...[
              _buildExternalLinkButton(link.label, link.url, link.color, link.icon),
              const SizedBox(width: 8),
            ],
          ],
        ),

        const SizedBox(height: fieldSpacing),
        TextField(
          controller: _pitchController,
          minLines: 2,
          maxLines: null,
          style: textStyle?.copyWith(fontWeight: FontWeight.w600),
          decoration: compactDecoration(
            l10n.noteCoreAppealHeader,
            hintText: l10n.noteCoreAppealPlaceholder,
          ),
        ),
        const SizedBox(height: fieldSpacing),
        TextField(
          controller: _expectedQuestionsController,
          minLines: 2,
          maxLines: null,
          style: textStyle?.copyWith(fontWeight: FontWeight.w600),
          decoration: compactDecoration(
            l10n.noteExpectedQuestionsHeader,
            hintText: l10n.noteExpectedQuestionsPlaceholder,
          ),
        ),
        const SizedBox(height: fieldSpacing),
        // 기존 summary, fit, risks 필드는 백업용으로 유지하거나 제거 (여기서는 제거하고 새로운 구조로 대체)

      ],
      if (!_isEditing) ...[
                    if (_note.role.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.work_outline, size: 18, color: cs.primary),
                                const SizedBox(width: 8),
                                Text(l10n.noteAppliedRole, style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _note.role,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_note.newsSummary.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAnalysisCard(context, l10n.noteNewsSummaryHeader, _note.newsSummary, cs.primary),
                    ],
                    if (_note.businessDirection.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAnalysisCard(context, l10n.noteBusinessDirectionHeader, _note.businessDirection, cs.primary),
                    ],
                    if (_note.jobConnection.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAnalysisCard(context, l10n.noteJobConnectionHeader, _note.jobConnection, cs.primary),
                    ],
                    if (_note.riskPoints.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAnalysisCard(context, l10n.noteRiskPointsHeader, _note.riskPoints, cs.error),
                    ],
                    if (_note.pitch.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAnalysisCard(context, l10n.notePitchLabel, _note.pitch, cs.secondary, isBold: true),
                    ],
                    if (_note.expectedQuestions.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildAnalysisCard(context, l10n.noteExpectedQuestionsHeader, _note.expectedQuestions, cs.tertiary, isBold: true),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        for (final link in _getSearchLinks(context, _note.companyName)) ...[
                          _buildExternalLinkButton(link.label, link.url, link.color, link.icon),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                    // 이전 summary, fit, risks 데이터가 있을 경우를 대비해 호환성 유지
                    if (_note.summary.trim().isNotEmpty && _note.newsSummary.trim().isEmpty) ...[
                      const SizedBox(height: 12),
                      _buildAnalysisCard(context, l10n.noteSummaryLabel, _note.summary, cs.primary),
                    ],
                    if (_note.fit.trim().isNotEmpty && _note.jobConnection.trim().isEmpty) ...[
                      const SizedBox(height: 12),
                      _buildAnalysisCard(context, l10n.noteFitLabel, _note.fit, cs.primary),
                    ],
                    if (_note.risks.isNotEmpty && _note.riskPoints.trim().isEmpty) ...[
                      const SizedBox(height: 12),
                      _buildAnalysisCard(context, l10n.noteRisksLabel, _note.risks.join('\n'), cs.error),
                    ],
                  ],
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.noteEpisodes, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                      TextButton(onPressed: _addStory, child: Text(l10n.add)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (_note.stories.isEmpty)
                    Text(l10n.noteNoEpisodes, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
                  else
                    ..._note.stories.map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _editStory(s),
                              onLongPress: () => _deleteStory(s),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            s.title.isEmpty ? l10n.noteNoTitle : s.title,
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                                          ),
                                        ),
                                        if (s.evidenceUrl.trim().isNotEmpty)
                                          InkWell(
                                            onTap: () async {
                                              final uri = Uri.parse(s.evidenceUrl.trim());
                                              final homeUrl = '${uri.scheme}://${uri.host}';
                                              await Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) => JobBrowserScreen(
                                                    initialUrl: s.evidenceUrl,
                                                    homeUrl: homeUrl,
                                                    title: '증거자료',
                                                  ),
                                                ),
                                              );
                                            },
                                            borderRadius: BorderRadius.circular(20),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Icon(Icons.link, size: 18, color: cs.primary),
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (s.metrics.trim().isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        s.metrics,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                    if (s.result.trim().isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        s.result,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                                        maxLines: 3,
                                        overflow: TextOverflow.clip,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(l10n.noteQuestionBank, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                      ),
                      TextButton(onPressed: _addQuestion, child: Text(l10n.add)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (_note.questionBank.isEmpty)
                    Text(l10n.noteNoQuestions, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant))
                  else
                    ..._note.questionBank.take(15).map(
                          (q) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onLongPress: () => _deleteQuestionBankItem(q),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Text(q, style: Theme.of(context).textTheme.bodyMedium),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(height: 10),
                  if (relatedSessions.isNotEmpty) ...[
                    Text(l10n.noteRecentInterviews, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    ...relatedSessions.take(5).map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                          ),
                          padding: const EdgeInsets.all(16),
                          width: double.infinity,
                          child: Text(
                            '${s.round.localizedLabel(l10n)} · ${s.heldAt.year}.${s.heldAt.month.toString().padLeft(2, '0')}.${s.heldAt.day.toString().padLeft(2, '0')} · ${l10n.noteQuestionCount(s.questions.length)}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableAnalysisCard(BuildContext context, String title, TextEditingController controller, Color color) {
    return _EditableAnalysisCard(
      title: title,
      controller: controller,
      color: color,
    );
  }

  Widget _buildAnalysisCard(BuildContext context, String title, String content, Color color, {bool isBold = false}) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: _buildMarkdownText(
            context,
            content,
            Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                  color: cs.onSurface,
                ),
            color,
          ),
        ),
      ],
    );
  }

  Widget _buildMarkdownText(BuildContext context, String text, TextStyle? style, Color linkColor) {
    return _EditableAnalysisCard.buildMarkdownText(context, text, style, linkColor);
  }
}

class _EditableAnalysisCard extends StatefulWidget {
  final String title;
  final TextEditingController controller;
  final Color color;

  const _EditableAnalysisCard({
    required this.title,
    required this.controller,
    required this.color,
  });

  @override
  State<_EditableAnalysisCard> createState() => _EditableAnalysisCardState();

  static Widget buildMarkdownText(BuildContext context, String text, TextStyle? style, Color linkColor) {
    final spans = <InlineSpan>[];
    // Combined regex for Link, Bold, Italic
    // Note: Order matters. Check for ** before * to avoid incorrect matching.
    // Link: \[([^\]]+)\]\(([^)]+)\)
    // Bold: \*\*([^*]+)\*\*
    // Italic: \*([^*]+)\*
    // Using lazy match .*? to handle content correctly
    final regex = RegExp(r'(\[(.*?)\]\((.*?)\))|(\*\*(.*?)\*\*)|(\*(.*?)\*)');
    
    int lastMatchEnd = 0;
    for (final match in regex.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }
      
      if (match.group(1) != null) {
        // Link
        final linkText = match.group(2)!;
        final linkUrl = match.group(3)!;
        
        spans.add(TextSpan(
          text: linkText,
          style: style?.copyWith(
            color: linkColor, 
            decoration: TextDecoration.underline, 
            fontWeight: FontWeight.bold
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              final uri = Uri.parse(linkUrl.trim());
              final homeUrl = '${uri.scheme}://${uri.host}';
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JobBrowserScreen(
                    initialUrl: linkUrl,
                    homeUrl: homeUrl,
                    title: '링크',
                  ),
                ),
              );
            },
        ));
      } else if (match.group(4) != null) {
        // Bold
        final boldText = match.group(5)!;
        spans.add(TextSpan(
          text: boldText,
          style: style?.copyWith(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(6) != null) {
        // Italic
        final italicText = match.group(7)!;
        spans.add(TextSpan(
          text: italicText,
          style: style?.copyWith(fontStyle: FontStyle.italic),
        ));
      }
      
      lastMatchEnd = match.end;
    }
    
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd)));
    }
    
    return Text.rich(
      TextSpan(children: spans),
      style: style,
    );
  }
}

class _EditableAnalysisCardState extends State<_EditableAnalysisCard> {
  bool _isEditing = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        setState(() => _isEditing = false);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    
    if (_isEditing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: widget.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _isEditing = false),
                  child: Text(l10n.done, style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: true,
            minLines: 2,
            maxLines: null,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14.0),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: cs.surfaceContainerLowest,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.color.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.color, width: 1.5),
              ),
            ),
          ),
        ],
      );
    }

    return ValueListenableBuilder(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final text = value.text;
        final isEmpty = text.trim().isEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 14,
                        decoration: BoxDecoration(
                          color: widget.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: widget.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                  if (!isEmpty)
                    InkWell(
                      onTap: () => setState(() => _isEditing = true),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 14, color: widget.color),
                            const SizedBox(width: 4),
                            Text(
                              l10n.edit,
                              style: TextStyle(
                                color: widget.color,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: widget.color.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isEmpty)
                    InkWell(
                      onTap: () => setState(() => _isEditing = true),
                      child: Text(
                        l10n.noteAiAutoFillHint,
                        style: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                      ),
                    )
                  else
                    _EditableAnalysisCard.buildMarkdownText(
                      context,
                      text,
                      Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.35,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                      widget.color,
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StoryEditorSheet extends StatefulWidget {
  const _StoryEditorSheet({required this.initial});

  final CompanyStory? initial;

  @override
  State<_StoryEditorSheet> createState() => _StoryEditorSheetState();
}

class _StoryEditorSheetState extends State<_StoryEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _situation;
  late final TextEditingController _action;
  late final TextEditingController _result;
  late final TextEditingController _metrics;
  late final TextEditingController _evidenceUrl;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  TextEditingController? _activeSttController;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = TextEditingController(text: i?.title ?? '');
    _situation = TextEditingController(text: i?.situation ?? '');
    _action = TextEditingController(text: i?.action ?? '');
    _result = TextEditingController(text: i?.result ?? '');
    _metrics = TextEditingController(text: i?.metrics ?? '');
    _evidenceUrl = TextEditingController(text: i?.evidenceUrl ?? '');
    _initSpeech();
  }

  void _initSpeech() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) {
          debugPrint('STT Error: ${val.errorMsg}');
          if (mounted) {
            setState(() {
              _speechEnabled = false;
              _activeSttController = null;
            });
            String message = l10n.sttError;
            if (val.errorMsg == 'error_permission') {
              message = l10n.micPermissionDenied;
            } else if (val.errorMsg == 'error_speech_timeout') {
              message = l10n.sttTimeout;
            } else if (val.errorMsg == 'error_no_match') {
              message = l10n.sttNoMatch;
            } else if (val.errorMsg == 'error_network') {
              message = l10n.sttNetworkError;
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        onStatus: (val) {
          if (mounted) setState(() {});
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('STT Init failed: $e');
    }
  }

  void _toggleListening(TextEditingController controller) async {
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }

    if (_speechToText.isListening && _activeSttController == controller) {
      await _speechToText.stop();
      setState(() => _activeSttController = null);
      return;
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    _activeSttController = controller;
    _lastWords = '';
    
    try {
      final locales = await _speechToText.locales();
      final currentLocale = Localizations.localeOf(context);
      final langCode = currentLocale.languageCode;
      
      String? targetLocaleId;
      if (langCode == 'ko') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'ko_KR' || l.localeId.startsWith('ko'), orElse: () => locales.first).localeId;
      } else if (langCode == 'en') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'en_US' || l.localeId.startsWith('en'), orElse: () => locales.first).localeId;
      } else if (langCode == 'ja') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'ja_JP' || l.localeId.startsWith('ja'), orElse: () => locales.first).localeId;
      } else if (langCode == 'zh') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'zh_CN' || l.localeId == 'zh_TW' || l.localeId.startsWith('zh'), orElse: () => locales.first).localeId;
      } else if (langCode == 'hi') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'hi_IN' || l.localeId.startsWith('hi'), orElse: () => locales.first).localeId;
      }

      await _speechToText.listen(
        onResult: (result) {
          if (mounted && _activeSttController == controller) {
            setState(() {
              _lastWords = result.recognizedWords;
              if (result.finalResult) {
                final currentText = controller.text;
                final newText = _lastWords;
                if (currentText.isEmpty) {
                  controller.text = newText;
                } else {
                  final suffix = currentText.endsWith(' ') || currentText.endsWith('\n') ? '' : ' ';
                  controller.text = '$currentText$suffix$newText';
                }
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
                _lastWords = '';
                _activeSttController = null;
              }
            });
          }
        },
        localeId: targetLocaleId,
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('STT Listen failed: $e');
      _activeSttController = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    _title.dispose();
    _situation.dispose();
    _action.dispose();
    _result.dispose();
    _metrics.dispose();
    _evidenceUrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final initial = widget.initial;
    final cs = Theme.of(context).colorScheme;

    Widget buildSTTField(TextEditingController controller, String label, String hint, {int minLines = 1, int maxLines = 1}) {
      final isListening = _speechToText.isListening && _activeSttController == controller;
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
              filled: true,
              fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              suffixIcon: IconButton(
                icon: Icon(
                  isListening ? Icons.stop : Icons.mic,
                  color: isListening ? Colors.red : cs.primary,
                ),
                onPressed: () => _toggleListening(controller),
              ),
            ),
          ),
          if (isListening && _lastWords.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                l10n.recognizingText(_lastWords),
                style: TextStyle(fontSize: 11, color: cs.primary, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottom + safeBottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              initial == null ? l10n.noteAddEpisode : l10n.noteEditEpisode,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                labelText: l10n.noteEpisodeTitle,
                hintText: l10n.noteEpisodeTitleHint,
                hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _metrics,
              decoration: InputDecoration(
                labelText: l10n.noteEpisodeMetrics,
                hintText: l10n.noteEpisodeMetricsHint,
                hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: 16),
            buildSTTField(_situation, l10n.noteEpisodeSituation, l10n.noteEpisodeSituationHint, minLines: 2, maxLines: 5),
            const SizedBox(height: 16),
            buildSTTField(_action, l10n.noteEpisodeAction, l10n.noteEpisodeActionHint, minLines: 2, maxLines: 5),
            const SizedBox(height: 16),
            buildSTTField(_result, l10n.noteEpisodeResult, l10n.noteEpisodeResultHint, minLines: 2, maxLines: 5),
            const SizedBox(height: 16),
            TextField(
              controller: _evidenceUrl,
              decoration: InputDecoration(
                labelText: l10n.noteEpisodeEvidence,
                hintText: l10n.noteEpisodeEvidenceHint,
                hintStyle: TextStyle(color: cs.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                final now = DateTime.now();
                final story = CompanyStory(
                  id: initial?.id ?? '${now.microsecondsSinceEpoch}',
                  title: _title.text.trim(),
                  situation: _situation.text.trim(),
                  action: _action.text.trim(),
                  result: _result.text.trim(),
                  metrics: _metrics.text.trim(),
                  evidenceUrl: _evidenceUrl.text.trim(),
                );
                Navigator.of(context).pop(story);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleQuestionEditorSheet extends StatefulWidget {
  const _SimpleQuestionEditorSheet();

  @override
  State<_SimpleQuestionEditorSheet> createState() => _SimpleQuestionEditorSheetState();
}

class _SimpleQuestionEditorSheetState extends State<_SimpleQuestionEditorSheet> {
  late final TextEditingController _controller;
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _initSpeech();
  }

  void _initSpeech() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) {
          debugPrint('STT Error: ${val.errorMsg}');
          if (mounted) {
            setState(() {
              _speechEnabled = false;
            });
            String message = l10n.sttError;
            if (val.errorMsg == 'error_permission') {
              message = l10n.micPermissionDenied;
            } else if (val.errorMsg == 'error_speech_timeout') {
              message = l10n.sttTimeout;
            } else if (val.errorMsg == 'error_no_match') {
              message = l10n.sttNoMatch;
            } else if (val.errorMsg == 'error_network') {
              message = l10n.sttNetworkError;
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        onStatus: (val) {
          debugPrint('STT Status: $val');
          if (mounted) setState(() {});
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('STT Init failed: $e');
    }
  }

  void _toggleListening() async {
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
      if (mounted) setState(() {});
      return;
    }

    _lastWords = '';
    try {
      final locales = await _speechToText.locales();
      final currentLocale = Localizations.localeOf(context);
      final langCode = currentLocale.languageCode;
      
      String? targetLocaleId;
      if (langCode == 'ko') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'ko_KR' || l.localeId.startsWith('ko'), orElse: () => locales.first).localeId;
      } else if (langCode == 'en') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'en_US' || l.localeId.startsWith('en'), orElse: () => locales.first).localeId;
      } else if (langCode == 'ja') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'ja_JP' || l.localeId.startsWith('ja'), orElse: () => locales.first).localeId;
      } else if (langCode == 'zh') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'zh_CN' || l.localeId == 'zh_TW' || l.localeId.startsWith('zh'), orElse: () => locales.first).localeId;
      } else if (langCode == 'hi') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'hi_IN' || l.localeId.startsWith('hi'), orElse: () => locales.first).localeId;
      }
      
      await _speechToText.listen(
        onResult: (result) {
          if (mounted) {
            setState(() {
              _lastWords = result.recognizedWords;
              if (result.finalResult) {
                final currentText = _controller.text;
                final newText = _lastWords;
                if (currentText.isEmpty) {
                  _controller.text = newText;
                } else {
                  final suffix = (currentText.endsWith(' ') || currentText.endsWith('\n')) ? '' : ' ';
                  _controller.text = '$currentText$suffix$newText';
                }
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length),
                );
                _lastWords = '';
              }
            });
          }
        },
        localeId: targetLocaleId,
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('STT Listen failed: $e');
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom + safeBottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.noteAddQuestion,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noteAddQuestionHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.noteQuestionLabel,
                hintText: l10n.noteQuestionHint,
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withOpacity(0.5),
                  fontSize: 13,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: IconButton(
                  icon: Icon(
                    _speechToText.isListening ? Icons.stop : Icons.mic,
                    color: _speechToText.isListening ? Colors.red : cs.primary,
                  ),
                  onPressed: _toggleListening,
                ),
              ),
            ),
            if (_speechToText.isListening && _lastWords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  l10n.recognizingText(_lastWords),
                  style: TextStyle(fontSize: 12, color: cs.primary, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }
}

class InterviewSessionDetailScreen extends StatefulWidget {
  const InterviewSessionDetailScreen({
    super.key,
    required this.initial,
    required this.companies,
  });

  final InterviewSession initial;
  final List<CompanyNote> companies;

  @override
  State<InterviewSessionDetailScreen> createState() => _InterviewSessionDetailScreenState();
}

class _InterviewSessionDetailScreenState extends State<InterviewSessionDetailScreen> {
  late InterviewSession _session;

  @override
  void initState() {
    super.initState();
    _session = widget.initial;
  }

  Future<void> _editTop() async {
    final appState = AppStateScope.of(context);
    final companyRoles = <String, String>{};
    final sortedDeadlines = appState.deadlines.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    for (final d in sortedDeadlines) {
      if (d.companyName.trim().isNotEmpty) {
        companyRoles[d.companyName.trim()] = d.jobTitle;
      }
    }

    final updated = await Navigator.of(context, rootNavigator: false).push<InterviewSession>(
      MaterialPageRoute(
        builder: (_) => _InterviewSessionEditorSheet(
          companies: widget.companies,
          initial: _session,
          presetCompany: null,
          companyRoles: companyRoles,
        ),
      ),
    );
    if (updated == null) return;
    setState(() => _session = updated);
  }

  Future<void> _addQuestion() async {
    final created = await showModalBottomSheet<QuestionNote>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _QuestionEditorSheet(initial: null),
    );
    if (created == null) return;
    final now = DateTime.now();
    final next = _session.copyWith(questions: [created, ..._session.questions], updatedAt: now);
    setState(() => _session = next);
  }

  Future<void> _editQuestion(QuestionNote q) async {
    final updated = await showModalBottomSheet<QuestionNote>(
      context: context,
      useRootNavigator: true,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _QuestionEditorSheet(initial: q),
    );
    if (updated == null) return;
    final now = DateTime.now();
    final nextQuestions = _session.questions.map((x) => x.id == updated.id ? updated : x).toList(growable: false);
    setState(() => _session = _session.copyWith(questions: nextQuestions, updatedAt: now));
  }

  Future<void> _deleteQuestion(QuestionNote q) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteDeleteQuestionTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(l10n.noteDeleteConfirm(q.question.isEmpty ? l10n.noteQuestion : q.question, l10n.noteQuestion)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final now = DateTime.now();
      final nextQuestions = _session.questions.where((x) => x.id != q.id).toList(growable: false);
      setState(() => _session = _session.copyWith(questions: nextQuestions, updatedAt: now));
    }
  }

  Future<void> _deleteSession() async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.noteDeleteInterviewTitle, style: const TextStyle(fontWeight: FontWeight.w900)),
        content: Text(l10n.noteDeleteSessionConfirm(_session.companyName, _session.round.localizedLabel(l10n))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      Navigator.of(context).pop('delete');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _MainHeader(
              title: _session.companyName.isEmpty ? l10n.noteTabInterview : _session.companyName,
              onBack: () => Navigator.of(context).pop(_session),
              primaryAction: IconButton(onPressed: _editTop, icon: const Icon(Icons.edit)),
              secondaryAction: IconButton(
                onPressed: _deleteSession,
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.error,
                tooltip: l10n.delete,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_session.round.localizedLabel(l10n)} · ${_session.heldAt.year}.${_session.heldAt.month.toString().padLeft(2, '0')}.${_session.heldAt.day.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800),
                    ),
                  ),
                  TextButton(onPressed: _addQuestion, child: Text(l10n.add)),
                ],
              ),
            ),
            Expanded(
              child: _session.questions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l10n.noteEmptyQuestions,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      itemCount: _session.questions.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final q = _session.questions[index];
                        return Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _editQuestion(q),
                              onLongPress: () => _deleteQuestion(q),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          q.question.isEmpty ? l10n.noteQuestion : q.question,
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                                          maxLines: 3,
                                          overflow: TextOverflow.clip,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: q.reviewState.color(cs),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          q.reviewState.localizedLabel(l10n),
                                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                color: q.reviewState.onColor(cs),
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (q.answerAtTheTime.trim().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      q.answerAtTheTime,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                                      maxLines: 4,
                                      overflow: TextOverflow.clip,
                                    ),
                                  ],
                                  if (q.nextAction.trim().isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Text(
                                      l10n.noteNextAction(q.nextAction),
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w700),
                                      maxLines: 2,
                                      overflow: TextOverflow.clip,
                                    ),
                                  ],
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
      ),
    );
  }
}

class _QuestionEditorSheet extends StatefulWidget {
  const _QuestionEditorSheet({required this.initial});

  final QuestionNote? initial;

  @override
  State<_QuestionEditorSheet> createState() => _QuestionEditorSheetState();
}

class _QuestionEditorSheetState extends State<_QuestionEditorSheet> {
  static const _pitfallKeys = <String>[
    'pitfallMissingConcept',
    'pitfallVagueLogic',
    'pitfallLackOfExamples',
    'pitfallNoMetrics',
    'pitfallTooWordy',
    'pitfallUnclearPoint',
  ];

  late final TextEditingController _question;
  late final TextEditingController _intent;
  late final TextEditingController _answerAtTheTime;
  late final TextEditingController _improved60;
  late final TextEditingController _improved120;
  late final TextEditingController _nextAction;
  late Set<String> _pitfalls;
  ReviewState _state = ReviewState.needsReview;
  int _feeling = 3;
  bool _showAdvanced = false;

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  TextEditingController? _activeSttController;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _question = TextEditingController(text: i?.question ?? '');
    _intent = TextEditingController(text: i?.intent ?? '');
    _answerAtTheTime = TextEditingController(text: i?.answerAtTheTime ?? '');
    _improved60 = TextEditingController(text: i?.improved60 ?? '');
    _improved120 = TextEditingController(text: i?.improved120 ?? '');
    _nextAction = TextEditingController(text: i?.nextAction ?? '');
    _pitfalls = {...(i?.pitfalls ?? const <String>[])};
    _state = i?.reviewState ?? ReviewState.needsReview;
    _feeling = i?.feeling ?? 3;
    _showAdvanced = i != null && (i.intent.isNotEmpty || i.improved60.isNotEmpty || i.improved120.isNotEmpty || i.pitfalls.isNotEmpty || i.nextAction.isNotEmpty);
    _initSpeech();
  }

  void _initSpeech() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (val) {
          debugPrint('STT Error: ${val.errorMsg}');
          if (mounted) {
            setState(() {
              _speechEnabled = false;
              _activeSttController = null;
            });
            String message = l10n.sttError;
            if (val.errorMsg == 'error_permission') {
              message = l10n.micPermissionDenied;
            } else if (val.errorMsg == 'error_speech_timeout') {
              message = l10n.sttTimeout;
            } else if (val.errorMsg == 'error_no_match') {
              message = l10n.sttNoMatch;
            } else if (val.errorMsg == 'error_network') {
              message = l10n.sttNetworkError;
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
          }
        },
        onStatus: (val) {
          debugPrint('STT Status: $val');
          if (mounted) {
            setState(() {});
          }
        },
      );
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('STT Init failed: $e');
      if (mounted) {
        setState(() => _speechEnabled = false);
      }
    }
  }

  void _toggleListening(TextEditingController controller) async {
    if (!_speechEnabled) {
      _initSpeech();
      return;
    }
    
    if (_speechToText.isListening && _activeSttController == controller) {
      await _speechToText.stop();
      setState(() => _activeSttController = null);
      return;
    }

    if (_speechToText.isListening) {
      await _speechToText.stop();
    }

    _activeSttController = controller;
    _lastWords = '';
    
    try {
      final locales = await _speechToText.locales();
      final currentLocale = Localizations.localeOf(context);
      final langCode = currentLocale.languageCode;
      
      // 현재 앱 언어에 맞는 STT 로케일 찾기
      String? targetLocaleId;
      
      if (langCode == 'ko') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'ko_KR' || l.localeId.startsWith('ko'), orElse: () => locales.first).localeId;
      } else if (langCode == 'en') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'en_US' || l.localeId.startsWith('en'), orElse: () => locales.first).localeId;
      } else if (langCode == 'ja') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'ja_JP' || l.localeId.startsWith('ja'), orElse: () => locales.first).localeId;
      } else if (langCode == 'zh') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'zh_CN' || l.localeId == 'zh_TW' || l.localeId.startsWith('zh'), orElse: () => locales.first).localeId;
      } else if (langCode == 'hi') {
        targetLocaleId = locales.firstWhere((l) => l.localeId == 'hi_IN' || l.localeId.startsWith('hi'), orElse: () => locales.first).localeId;
      }

      await _speechToText.listen(
        onResult: (result) {
          if (mounted && _activeSttController == controller) {
            setState(() {
              _lastWords = result.recognizedWords;
              if (result.finalResult) {
                final currentText = controller.text;
                final newText = _lastWords;
                if (currentText.isEmpty) {
                  controller.text = newText;
                } else {
                  final suffix = (currentText.endsWith(' ') || currentText.endsWith('\n')) ? '' : ' ';
                  controller.text = '$currentText$suffix$newText';
                }
                controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: controller.text.length),
                );
                _lastWords = '';
                _activeSttController = null;
              }
            });
          }
        },
        localeId: targetLocaleId,
        listenOptions: SpeechListenOptions(
          cancelOnError: false,
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
    } catch (e) {
      debugPrint('STT Listen failed: $e');
      _activeSttController = null;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    _question.dispose();
    _intent.dispose();
    _answerAtTheTime.dispose();
    _improved60.dispose();
    _improved120.dispose();
    _nextAction.dispose();
    super.dispose();
  }

  String _getPitfallLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'pitfallMissingConcept':
        return l10n.pitfallMissingConcept;
      case 'pitfallVagueLogic':
        return l10n.pitfallVagueLogic;
      case 'pitfallLackOfExamples':
        return l10n.pitfallLackOfExamples;
      case 'pitfallNoMetrics':
        return l10n.pitfallNoMetrics;
      case 'pitfallTooWordy':
        return l10n.pitfallTooWordy;
      case 'pitfallUnclearPoint':
        return l10n.pitfallUnclearPoint;
      default:
        return key;
    }
  }

  Widget _buildFeelingButton(int score, String label, Color color) {
    final isSelected = _feeling == score;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: InkWell(
          onTap: () => setState(() => _feeling = score),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? color : color.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _getFeelingEmoji(score),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getFeelingEmoji(int score) {
    switch (score) {
      case 1: return '😫';
      case 2: return '😟';
      case 3: return '😐';
      case 4: return '🤔';
      case 5: return '😎';
      default: return '😐';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final initial = widget.initial;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom + safeBottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    initial == null ? l10n.noteQuestionRecord : l10n.noteEditQuestion,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                  ),
                ),
                if (initial != null)
                  IconButton(
                    icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
                    tooltip: l10n.detailRecordSettings,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // --- 초간단 모드 (기본 필드) ---
            TextField(
              controller: _question,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.noteQuestionLabel,
                hintText: l10n.noteQuestionHint,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: IconButton(
                  icon: Icon(
                    (_speechToText.isListening && _activeSttController == _question) ? Icons.stop : Icons.mic,
                    color: (_speechToText.isListening && _activeSttController == _question) ? Colors.red : Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _toggleListening(_question),
                ),
              ),
            ),
            if (_speechToText.isListening && _activeSttController == _question && _lastWords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  l10n.recognizingText(_lastWords),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerAtTheTime,
              minLines: 3,
              maxLines: 8,
              decoration: InputDecoration(
                labelText: l10n.noteAnswerAtTheTime,
                hintText: l10n.inputMyAnswerHint,
                hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                suffixIcon: IconButton(
                  icon: Icon(
                    (_speechToText.isListening && _activeSttController == _answerAtTheTime) ? Icons.stop : Icons.mic,
                    color: (_speechToText.isListening && _activeSttController == _answerAtTheTime) ? Colors.red : Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => _toggleListening(_answerAtTheTime),
                ),
              ),
            ),
            if (_speechToText.isListening && _activeSttController == _answerAtTheTime && _lastWords.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Text(
                  l10n.recognizingText(_lastWords),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                ),
              ),
            const SizedBox(height: 16),
            Text(l10n.interviewFeelingTitle, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFeelingButton(1, l10n.feelingBad, Colors.red),
                  _buildFeelingButton(2, l10n.feelingDisappointed, Colors.orange),
                  _buildFeelingButton(3, l10n.feelingNormal, Colors.blueGrey),
                  _buildFeelingButton(4, l10n.feelingAmbiguous, Colors.blue),
                  _buildFeelingButton(5, l10n.feelingGood, Colors.green),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- AI 분석/심화 기록 섹션 ---
            InkWell(
              onTap: () => setState(() => _showAdvanced = !_showAdvanced),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Icon(
                            _showAdvanced ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n.viewAdvanced,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Icon(
                            _showAdvanced ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
                  ],
                ),
              ),
            ),

            if (_showAdvanced) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _intent,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.noteIntent,
                  hintText: l10n.noteIntentHint,
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  suffixIcon: IconButton(
                    icon: Icon(
                      (_speechToText.isListening && _activeSttController == _intent) ? Icons.stop : Icons.mic,
                      color: (_speechToText.isListening && _activeSttController == _intent) ? Colors.red : Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => _toggleListening(_intent),
                  ),
                ),
              ),
              if (_speechToText.isListening && _activeSttController == _intent && _lastWords.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    l10n.recognizingText(_lastWords),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _improved60,
                          minLines: 2,
                          maxLines: 5,
                          decoration: InputDecoration(
                            labelText: l10n.noteImproved60,
                            hintText: l10n.noteImproved60Hint,
                            hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                            filled: true,
                            fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            suffixIcon: IconButton(
                              icon: Icon(
                                (_speechToText.isListening && _activeSttController == _improved60) ? Icons.stop : Icons.mic,
                                color: (_speechToText.isListening && _activeSttController == _improved60) ? Colors.red : Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () => _toggleListening(_improved60),
                            ),
                          ),
                        ),
                        if (_speechToText.isListening && _activeSttController == _improved60 && _lastWords.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 4),
                            child: Text(
                              l10n.recognizingText(_lastWords),
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _improved120,
                minLines: 2,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: l10n.noteImproved120,
                  hintText: l10n.noteImproved120Hint,
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  suffixIcon: IconButton(
                    icon: Icon(
                      (_speechToText.isListening && _activeSttController == _improved120) ? Icons.stop : Icons.mic,
                      color: (_speechToText.isListening && _activeSttController == _improved120) ? Colors.red : Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => _toggleListening(_improved120),
                  ),
                ),
              ),
              if (_speechToText.isListening && _activeSttController == _improved120 && _lastWords.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                  l10n.recognizingText(_lastWords),
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                ),
                ),
              const SizedBox(height: 16),
              Text(l10n.notePitfalls, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _pitfallKeys.map((key) {
                  final label = _getPitfallLabel(key, l10n);
                  final selected = _pitfalls.contains(label);
                  return FilterChip(
                    label: Text(label),
                    selected: selected,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _pitfalls.add(label);
                      } else {
                        _pitfalls.remove(label);
                      }
                    }),
                    side: BorderSide.none,
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    selectedColor: Theme.of(context).colorScheme.primaryContainer,
                    labelStyle: TextStyle(
                      color: selected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nextAction,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.noteNextActionLabel,
                  hintText: l10n.noteNextActionHint,
                  hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5), fontSize: 13),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  suffixIcon: IconButton(
                    icon: Icon(
                      (_speechToText.isListening && _activeSttController == _nextAction) ? Icons.stop : Icons.mic,
                      color: (_speechToText.isListening && _activeSttController == _nextAction) ? Colors.red : Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => _toggleListening(_nextAction),
                  ),
                ),
              ),
              if (_speechToText.isListening && _activeSttController == _nextAction && _lastWords.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(
                    l10n.recognizingText(_lastWords),
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontStyle: FontStyle.italic),
                  ),
                ),
            ],

            const SizedBox(height: 16),
            DropdownButtonFormField<ReviewState>(
              key: ValueKey(_state),
              value: _state,
              decoration: InputDecoration(
                labelText: l10n.noteReviewStatus,
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              items: ReviewState.values.map((s) => DropdownMenuItem(
                value: s,
                child: Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 16,
                      color: s == ReviewState.needsReview ? Colors.amber : Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    Text(s.localizedLabel(l10n), style: const TextStyle(fontSize: 15)),
                  ],
                ),
              )).toList(growable: false),
              onChanged: (v) => setState(() => _state = v ?? ReviewState.needsReview),
              icon: const Icon(Icons.arrow_drop_down_rounded, size: 28),
              dropdownColor: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              menuMaxHeight: 300,
              isExpanded: true,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                final question = _question.text.trim();
                if (question.isEmpty) return;
                final now = DateTime.now();
                final nextReviewAt = (_state == ReviewState.needsReview) ? now.add(const Duration(days: 3)) : null;
                final note = QuestionNote(
                  id: initial?.id ?? '${now.microsecondsSinceEpoch}',
                  question: question,
                  intent: _intent.text.trim(),
                  answerAtTheTime: _answerAtTheTime.text.trim(),
                  improved60: _improved60.text.trim(),
                  improved120: _improved120.text.trim(),
                  pitfalls: _pitfalls.toList(growable: false),
                  nextAction: _nextAction.text.trim(),
                  reviewState: _state,
                  nextReviewAt: initial?.nextReviewAt ?? nextReviewAt,
                  feeling: _feeling,
                );
                Navigator.of(context).pop(note);
              },
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
