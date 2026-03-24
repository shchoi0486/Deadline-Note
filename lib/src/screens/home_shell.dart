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
        
        // 탭 이동 및 모든 네비게이터 초기화
        setState(() {
          _index = 0;
          _tabHistory.remove(0); // 0번 탭으로 이동하므로 히스토리에서 0을 제거하여 중복 방지
        });
        
        // 모든 탭의 네비게이터를 루트로 되돌림
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          for (final navKey in _navigatorKeys) {
            final nav = navKey.currentState;
            if (nav != null && nav.canPop()) {
              nav.popUntil((r) => r.isFirst);
            }
          }
        });
      };
      appState.addListener(_appStateListener!);
      final initial = await appState.getInitialSharedText();
      if (!mounted) return;
      if (initial != null && initial.isNotEmpty) {
        debugPrint('HomeShell: Initial shared text found: $initial');
        setState(() => _index = 2);
        // 네비게이터가 준비될 때까지 잠시 대기 후 푸시
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final nav = _navigatorKeys[2].currentState;
          if (nav != null) {
            // 중복 푸시 방지를 위해 기존 스택 정리
            nav.popUntil((r) => r.isFirst);
            await nav.push(
              MaterialPageRoute(builder: (_) => AddFromShareScreen(sharedText: initial)),
            );
          }
        });
      }

      _shareSub = appState.sharedTextStream.listen((text) async {
        if (!mounted || text.isEmpty) return;
        debugPrint('HomeShell: Stream shared text received: $text');
        
        // 이미 해당 텍스트를 처리 중이거나 동일한 텍스트가 인입되는 경우를 위한 간단한 체크
        // (필요 시 더 정교한 중복 제거 로직 추가 가능)
        
        setState(() => _index = 2);
        final nav = _navigatorKeys[2].currentState;
        if (nav != null) {
          nav.popUntil((r) => r.isFirst);
          await nav.push(
            MaterialPageRoute(builder: (_) => AddFromShareScreen(sharedText: text)),
          );
        }
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
        onPopInvokedWithResult: (didPop, result) async {
          debugPrint('HomeShell: onPopInvoked didPop=$didPop index=$_index');
          // didPop이 true라는 것은 이미 팝(종료)이 진행되었다는 뜻이므로 아무것도 하지 않음
          if (didPop) return;
          
          // 시스템 뒤로가기 발생 시 직접 처리 로직 실행
          await _handleBackPressed();
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
    if (_isHandlingBack) {
      debugPrint('HomeShell: Already handling back button. Ignoring...');
      return;
    }
    _isHandlingBack = true;

    try {
      debugPrint('HomeShell: Handling back button at index $_index');
      final currentNavigator = _navigatorKeys[_index].currentState;
      
      // 1. 중첩 네비게이터 처리 (인앱 브라우저, 직접 추가 화면 등)
      if (currentNavigator != null && currentNavigator.canPop()) {
        debugPrint('HomeShell: Nested navigator can pop. Attempting maybePop().');
        final handled = await currentNavigator.maybePop();
        debugPrint('HomeShell: Nested maybePop result handled=$handled');
        
        // handled가 true이면 실제로 팝(Pop)이 발생한 것이고 (브라우저가 닫혔거나 서브 페이지에서 나감),
        // false이면 하위의 PopScope(예: JobBrowserScreen)에서 뒤로가기를 가로채서 자체 처리 중인 경우임.
        // 어느 쪽이든 HomeShell 수준에서의 추가 동작(종료 창 등)은 여기서 중단해야 함.
        return;
      }

      // 2. 추가 탭(Add Tab, Index 2) 루트 화면인 경우 -> 종료 확인 창 표시
      if (_index == 2) {
        debugPrint('HomeShell: At Add tab root (Index 2). Showing exit confirmation dialog.');
        final shouldExit = await _showExitConfirmDialog();
        debugPrint('HomeShell: Exit dialog result: $shouldExit');

        if (!mounted) return;
        if (shouldExit) {
          debugPrint('HomeShell: User confirmed exit. Closing app.');
          await _exitApp();
        }
        // 종료를 취소했거나 다이얼로그 바깥을 눌렀을 경우, 앱이 꺼지지 않도록 여기서 리턴
        return;
      }

      // 3. 다른 탭(Calendar, List, Notes, Settings)인 경우
      debugPrint('HomeShell: At tab $_index. Redirecting to Add tab (2).');
      // 다른 메뉴에서는 뒤로가기 시 무조건 추가 메뉴 화면으로 이동
      setState(() {
        _index = 2;
        // 탭 이동 시 히스토리에서 제거하여 루트로 인식하게 함
        _tabHistory.remove(2);
      });
      // 탭 전환 애니메이션 등을 고려하여 약간의 지연
      await Future.delayed(const Duration(milliseconds: 200));
      return;
    } catch (e) {
      debugPrint('Error in _handleBackPressed: $e');
    } finally {
      // 연속 클릭 방지용 지연 후 플래그 해제
      await Future.delayed(const Duration(milliseconds: 300));
      _isHandlingBack = false;
    }
  }

  Future<void> _exitApp() async {
    await SystemNavigator.pop();
  }

  Future<bool> _showExitConfirmDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final messages = [
      '오늘도 정말 수고 많으셨어요!\n내일은 더 좋은 기회가 올 거예요.',
      '당신의 열정을 응원합니다.\n포기하지 마세요!',
      '조금 늦더라도 괜찮아요.\n당신만의 속도로 가고 있는 거니까요.',
      '오늘의 노력이\n내일의 합격으로 이어질 거예요.',
      '당신은 충분히 잘하고 있습니다.\n스스로를 믿으세요.',
      '실패는 성공으로 가는 과정일 뿐이에요.\n다시 일어날 수 있어요!',
      '지치고 힘들 땐 잠시 쉬어가도 좋아요.\n당신은 소중하니까요.',
      '꿈을 향한 당신의 걸음을\nDeadline Note가 함께 응원합니다.',
      '당신이라는 원석이 곧\n보석처럼 빛날 날이 올 거예요.',
      '힘들었던 시간만큼\n더 큰 기쁨이 기다리고 있을 거예요.',
      '당신의 가능성은 무한합니다.\n자신감을 가지세요!',
      '한 걸음 한 걸음이 모여\n큰 성취를 이룰 거예요.',
      '당신의 가치를 알아주는 곳이\n반드시 나타날 거예요.',
      '오늘도 한 뼘 더 성장한\n당신을 칭찬해주세요.',
      '어두운 밤이 지나면\n반드시 밝은 아침이 찾아옵니다.',
      '당신은 결코 혼자가 아니에요.\n우리가 응원하고 있어요!',
      '지금의 인내가 훗날\n멋진 열매를 맺을 거예요.',
      '당신의 성실함은 배신하지 않을 거예요.\n힘내세요!',
      '세상에 단 하나뿐인\n당신의 꿈을 응원합니다.',
      '할 수 있다는 믿음이\n기적을 만듭니다.',
      '오늘도 최선을 다한\n당신에게 박수를 보냅니다.',
      '당신의 내일이 오늘보다\n더 반짝이기를 바랍니다.',
      '두려워하지 말고 나아가세요.\n당신은 할 수 있습니다!',
      '매일 조금씩 나아가는\n당신의 모습이 아름다워요.',
      '합격이라는 마침표가 머지않았습니다.\n조금만 더 힘내세요!',
      '당신의 열정적인 삶이\n멋진 결실을 맺을 거예요.',
      '스스로를 사랑하는 마음이\n가장 큰 힘이 됩니다.',
      '당신의 노력이 헛되지 않음을\n결과로 증명될 거예요.',
      '오늘도 꿈에 한 발짝 더\n가까워지셨네요!',
      '당신의 앞날에 꽃길만 가득하기를\n진심으로 기원합니다.',
    ];
    final randomMessage = messages[DateTime.now().millisecond % messages.length];

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        final cs = Theme.of(context).colorScheme;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          backgroundColor: cs.surface,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.exitConfirmTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: const SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: NativeAdWidget(),
                  ),
                ),
                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote_rounded, color: cs.primary.withOpacity(0.4), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          randomMessage,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                            height: 1.3,
                            letterSpacing: -0.3,
                          ),
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        child: Text(l10n.cancel),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
