import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state_scope.dart';
import '../widgets/ad_placeholder.dart';
import 'add_from_share_screen.dart';
import 'calendar_screen.dart';
import 'file_vault_screen.dart';
import 'list_screen.dart';
import 'settings_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final List<int> _tabHistory = [];
  int _index = 0;
  bool _isHandlingBack = false;
  StreamSubscription<String>? _shareSub;
  final _navigatorKeys = List<GlobalKey<NavigatorState>>.generate(5, (_) => GlobalKey<NavigatorState>());
  late final List<Widget> _tabNavigators;
  int _handledSavedRevision = 0;
  VoidCallback? _appStateListener;
  Object? _appStateForListener;

  @override
  void initState() {
    super.initState();
    _tabNavigators = [
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
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const AddFromShareScreen(sharedText: null)),
      ),
      Navigator(
        key: _navigatorKeys[3],
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const FileVaultScreen()),
      ),
      Navigator(
        key: _navigatorKeys[4],
        onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final appState = AppStateScope.of(context);
      _appStateForListener = appState;
      _handledSavedRevision = appState.lastSavedRevision;
      _appStateListener = () {
        final nextRevision = appState.lastSavedRevision;
        if (nextRevision == _handledSavedRevision) return;
        _handledSavedRevision = nextRevision;
        if (!mounted) return;
        setState(() => _index = 0);
        final nav = _navigatorKeys[0].currentState;
        nav?.popUntil((r) => r.isFirst);
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
    });
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    final listener = _appStateListener;
    final appState = _appStateForListener;
    if (listener != null && appState is ChangeNotifier) {
      appState.removeListener(listener);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isHandlingBack) return;
        unawaited(_handleBackPressed());
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: _tabNavigators),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            if (i == _index) {
              if (i == 0) AppStateScope.of(context).triggerCalendarReset();
              return;
            }
            setState(() {
              _tabHistory.remove(i);
              _tabHistory.add(_index);
              _index = i;
            });
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.calendar_month), label: '일정'),
            NavigationDestination(icon: Icon(Icons.view_list), label: '현황'),
            NavigationDestination(
              icon: _PlusTabIcon(selected: false),
              selectedIcon: _PlusTabIcon(selected: true),
              label: '추가',
            ),
            NavigationDestination(icon: Icon(Icons.folder), label: '파일함'),
            NavigationDestination(icon: Icon(Icons.settings), label: '설정'),
          ],
        ),
      ),
    );
  }

  Future<void> _handleBackPressed() async {
    if (!mounted) return;
    if (_isHandlingBack) return;
    _isHandlingBack = true;

    try {
      // 1) 현재 탭 스택 우선 팝
      final currentNav = _navigatorKeys[_index].currentState;
      if (currentNav != null && await currentNav.maybePop()) return;

      // 2) 다른 탭 중 팝 가능한 스택이 있으면 그 탭으로 이동
      //    (예: 캘린더 탭에서 열린 화면인데 _index가 2로 바뀌어 있는 경우)
      int? poppableTab;
      for (var i = 0; i < _navigatorKeys.length; i++) {
        final nav = _navigatorKeys[i].currentState;
        if (nav != null && nav.canPop()) {
          poppableTab = i;
          break;
        }
      }
      if (poppableTab != null && poppableTab != _index) {
        setState(() => _index = poppableTab!);
        return;
      }

      if (!mounted) return;

      if (_tabHistory.isNotEmpty) {
        setState(() {
          _index = _tabHistory.removeLast();
        });
        return;
      }

      if (_index != 0) {
        setState(() => _index = 0);
        return;
      }

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
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('종료하시겠습니까?'),
          content: const AdPlaceholder(),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('종료'),
            ),
          ],
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
    final cs = Theme.of(context).colorScheme;
    final bg = const Color(0xFF22C55E);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        Icons.add,
        color: selected ? cs.onPrimary : Colors.white,
        size: 22,
      ),
    );
  }
}
