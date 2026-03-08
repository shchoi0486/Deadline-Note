import 'package:flutter/material.dart';
import 'package:deadline_note/l10n/app_localizations.dart';
import '../state/app_state_scope.dart';
import 'home_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingData> _getPages(AppLocalizations l10n) => [
    OnboardingData(
      title: l10n.onboardingTitle1,
      subtitle: l10n.onboardingSubtitle1,
      imagePath: 'assets/images/onboarding/onboarding1.png',
      color: const Color(0xFF2E5BFF),
      imageAlignment: const Alignment(0, -0.85),
    ),
    OnboardingData(
      title: l10n.onboardingTitle2,
      subtitle: l10n.onboardingSubtitle2,
      imagePath: 'assets/images/onboarding/onboarding2.png',
      color: const Color(0xFF2E5BFF),
      imageAlignment: const Alignment(0, -0.85),
    ),
    OnboardingData(
      title: l10n.onboardingTitle3,
      subtitle: l10n.onboardingSubtitle3,
      imagePath: 'assets/images/onboarding/onboarding3.png',
      color: const Color(0xFF2E5BFF),
    ),
    OnboardingData(
      title: l10n.onboardingTitle4,
      subtitle: l10n.onboardingSubtitle4,
      imagePath: 'assets/images/onboarding/onboarding4.png',
      color: const Color(0xFF2E5BFF),
    ),
    OnboardingData(
      title: l10n.onboardingTitle5,
      subtitle: l10n.onboardingSubtitle5,
      imagePath: 'assets/images/onboarding/onboarding5.png',
      color: const Color(0xFF2E5BFF),
      imageAlignment: const Alignment(0, -0.6),
    ),
  ];

  void _onFinish() async {
    final appState = AppStateScope.of(context);
    await appState.updateSettings(appState.settings.copyWith(hasSeenOnboarding: true));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeShell(initialIndex: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = _getPages(l10n);
    final theme = Theme.of(context);
    final primaryColor = const Color(0xFF111111);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: Back Button and Page Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _currentPage > 0
                        ? IconButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOutCubic,
                              );
                            },
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF111111)),
                          )
                        : const SizedBox(height: 48),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        height: 6,
                        width: 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFF111111)
                              : const Color(0xFFD9D9D9),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(data: pages[index]);
                },
              ),
            ),
            // Bottom Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 58,
                child: FilledButton(
                  onPressed: () {
                    if (_currentPage == pages.length - 1) {
                      _onFinish();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOutCubic,
                      );
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF111111),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == pages.length - 1 ? l10n.getStarted : l10n.continueText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String subtitle;
  final String imagePath;
  final String? secondaryImagePath;
  final Color color;
  final Alignment imageAlignment;

  OnboardingData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    this.secondaryImagePath,
    required this.color,
    this.imageAlignment = const Alignment(0, -0.85),
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate dynamic spacing based on screen height
        final screenHeight = constraints.maxHeight;
        final topSpace = screenHeight * 0.05;
        final titleImageSpace = screenHeight * 0.04;
        
        return Column(
          children: [
            SizedBox(height: topSpace),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                data.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28, // Adjusted for responsiveness
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111111),
                  height: 1.2,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                data.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF444444),
                  height: 1.4,
                ),
              ),
            ),
            SizedBox(height: titleImageSpace),
            // Image Area: Flexible to prevent overflow
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      Image.asset(
                        data.imagePath,
                        fit: BoxFit.cover,
                        alignment: data.imageAlignment,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                          );
                        },
                      ),
                      if (data.secondaryImagePath != null)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              data.secondaryImagePath!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const SizedBox.shrink(); // 에셋이 없으면 아예 안보이게 처리
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20), // Bottom padding before button
          ],
        );
      },
    );
  }
}
