import 'package:flutter/material.dart';
import '../state/app_state_scope.dart';
import 'home_shell.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initAndNavigate();
      }
    });
  }

  Future<void> _initAndNavigate() async {
    final startTime = DateTime.now();
    
    try {
      // 1. AppState 초기화 (최대 3초 대기 후 강제 진행)
      final appState = AppStateScope.of(context);
      await appState.init().timeout(const Duration(seconds: 3), onTimeout: () {
        debugPrint('AppState init timed out');
      });
    } catch (e) {
      debugPrint('Error during AppState init: $e');
    }

    // 2. 최소 스플래시 유지 시간 (500ms)
    final elapsed = DateTime.now().difference(startTime);
    const minDuration = Duration(milliseconds: 500);
    if (elapsed < minDuration) {
      await Future.delayed(minDuration - elapsed);
    }

    if (!mounted) return;

    final appState = AppStateScope.of(context);
    final showOnboarding = !appState.settings.hasSeenOnboarding;

    // 3. 적절한 화면으로 부드럽게 전환
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
            showOnboarding ? const OnboardingScreen() : const HomeShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SizedBox.shrink(), // 아이콘을 제거하여 네이티브 스플래시와의 중복 방지
      ),
    );
  }
}
