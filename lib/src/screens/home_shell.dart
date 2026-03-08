import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:deadline_note/l10n/app_localizations.dart';

import '../state/app_state_scope.dart';
import '../widgets/native_ad_widget.dart';
import 'add_from_share_screen.dart';
import 'calendar_screen.dart';
import 'list_screen.dart';
import 'notes_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  final int initialIndex;
  const HomeShell({super.key, this.initialIndex = 0});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final List<int> _tabHistory = [];
  late int _index;
  int _addTabKeyCounter = 0;
  bool _isHandlingBack = false;
  StreamSubscription<String>? _shareSub;
  StreamSubscription<int>? _tabSub;
  final _navigatorKeys = List<GlobalKey<NavigatorState>>.generate(5, (_) => GlobalKey<NavigatorState>());
  int _handledSavedRevision = 0;
  VoidCallback? _appStateListener;
  Object? _appStateForListener;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = AppStateScope.of(context);
      _appStateForListener = appState;
      _handledSavedRevision = appState.lastSavedRevision;
      _appStateListener = () {
        final nextRevision = appState.lastSavedRevision;
        if (nextRevision == _handledSavedRevision) return;
        _handledSavedRevision = nextRevision;
        if (!mounted) return;
        
        // 탭 이동 및 화면 복구 (이미 해당 탭이면 팝만 수행)
        setState(() => _index = 0);
        
        // 다음 프레임에서 수행하여 UI 전환이 안정적으로 이루어지도록 함
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final nav = _navigatorKeys[0].currentState;
          if (nav != null && nav.canPop()) {
            nav.popUntil((r) => r.isFirst);
          }
        });
      };
      appState.addListener(_appStateListener!);
      final initial = await appState.getInitialSharedText();
      if (!mounted) return;
      if (initial != null) {
        setState(() => _index = 2);
        final nav = _navigatorKeys[2].currentState;
        nav?.popUntil((r) => r.isFirst);
        await (nav ?? Navigator.of(context)).push(
          MaterialPageRoute(builder: (_) => AddFromShareScreen(sharedText: initial)),
        );
      }

      _shareSub = appState.sharedTextStream.listen((text) async {
        if (!mounted) return;
        setState(() => _index = 2);
        final nav = _navigatorKeys[2].currentState;
        nav?.popUntil((r) => r.isFirst);
        await (nav ?? Navigator.of(context)).push(
          MaterialPageRoute(builder: (_) => AddFromShareScreen(sharedText: text)),
        );
      });

      _tabSub = appState.onTabChange.listen((index) {
        if (!mounted) return;
        setState(() {
          if (index == 2) {
            _addTabKeyCounter++;
            _navigatorKeys[2] = GlobalKey<NavigatorState>();
          }
          _tabHistory.remove(index);
          _tabHistory.add(_index);
          _index = index;
        });
      });
    });
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    _tabSub?.cancel();
    final listener = _appStateListener;
    final appState = _appStateForListener;
    if (listener != null && appState is ChangeNotifier) {
      appState.removeListener(listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final tabNavigators = [
      Navigator(
        key: _navigatorKeys[0],
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const CalendarScreen()),
      ),
      Navigator(
        key: _navigatorKeys[1],
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const ListScreen()),
      ),
      Navigator(
        key: _navigatorKeys[2],
        onGenerateRoute: (_) => MaterialPageRoute(
          builder: (_) => AddFromShareScreen(
            key: ValueKey('add_tab_$_addTabKeyCounter'),
            sharedText: null,
          ),
        ),
      ),
      Navigator(
        key: _navigatorKeys[3],
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const NotesScreen()),
      ),
      Navigator(
        key: _navigatorKeys[4],
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    ];

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          _handleBackPressed();
        },
        child: Scaffold(
          body: IndexedStack(index: _index, children: tabNavigators),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) {
              FocusManager.instance.primaryFocus?.unfocus();
              
              if (i == 0) {
                // 달력 탭 선택 시 항상 오늘 날짜 및 월간 보기로 리셋
                AppStateScope.of(context).triggerCalendarReset();
                
                // 만약 현재 탭이 달력이 아니었다면 탭 이동
                if (_index != 0) {
                  setState(() {
                    _tabHistory.remove(0);
                    _tabHistory.add(_index);
                    _index = 0;
                  });
                }
                
                // 서브 페이지가 열려있다면 루트로 이동
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  final nav = _navigatorKeys[0].currentState;
                  if (nav != null && nav.canPop()) {
                    nav.popUntil((r) => r.isFirst);
                  }
                });
                return;
              }

              if (i == _index) {
                if (i == 2) {
                  setState(() {
                    _addTabKeyCounter++;
                    _navigatorKeys[2] = GlobalKey<NavigatorState>();
                  });
                }
                return;
              }
              setState(() {
                if (i == 2) {
                  _addTabKeyCounter++;
                  _navigatorKeys[2] = GlobalKey<NavigatorState>();
                }
                _tabHistory.remove(i);
                _tabHistory.add(_index);
                _index = i;
              });
            },
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.calendar_month_outlined),
                selectedIcon: const Icon(Icons.calendar_month),
                label: l10n.tabCalendar,
              ),
              NavigationDestination(
                icon: const Icon(Icons.view_list_outlined),
                selectedIcon: const Icon(Icons.view_list),
                label: l10n.tabList,
              ),
              NavigationDestination(
                icon: const _PlusTabIcon(selected: false),
                selectedIcon: const _PlusTabIcon(selected: true),
                label: l10n.tabAdd,
              ),
              NavigationDestination(
                icon: const Icon(Icons.note_alt_outlined),
                selectedIcon: const Icon(Icons.note_alt),
                label: l10n.tabNotes,
              ),
              NavigationDestination(
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings),
                label: l10n.tabSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackPressed() async {
    if (!mounted) return;
    if (_isHandlingBack) return;
    _isHandlingBack = true;

    try {
      // 1) 현재 탭 스택 우선 팝 (서브 페이지가 열려있으면 종료하지 않음)
      final currentNav = _navigatorKeys[_index].currentState;
      if (currentNav != null) {
        final handled = await currentNav.maybePop();
        if (handled) return;
      }

      // 2) 탭 히스토리가 있으면 이전 탭으로 이동
      if (_tabHistory.isNotEmpty) {
        setState(() {
          _index = _tabHistory.removeLast();
        });
        return;
      }

      // 3) 루트 화면이라면 종료 확인 팝업 표시
      final shouldExit = await _showExitConfirmDialog();
      if (!mounted) return;
      if (shouldExit) {
        await SystemNavigator.pop();
      }
    } finally {
      _isHandlingBack = false;
    }
  }

  Future<bool> _showExitConfirmDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          backgroundColor: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.exitConfirmTitle,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // 광고를 위쪽으로 배치하고 크기를 제한
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: const NativeAdWidget(),
                  ),
                ),
                const SizedBox(height: 24),
                // 취소/종료 버튼을 아래쪽으로 배치
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          elevation: 0,
                        ),
                        child: Text(l10n.exitConfirmAction),
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
    return result ?? false;
  }
}

class _PlusTabIcon extends StatelessWidget {
  const _PlusTabIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.colorScheme.primary;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: bg.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Icon(
        Icons.add,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}
