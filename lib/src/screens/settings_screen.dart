import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final settings = appState.settings;

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
                                  '설정',
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('마감 알림',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('D-3 알림'),
                            value: settings.enableD3,
                            onChanged: (v) => appState.updateSettings(settings.copyWith(enableD3: v)),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('D-1 알림'),
                            value: settings.enableD1,
                            onChanged: (v) => appState.updateSettings(settings.copyWith(enableD1: v)),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('마감 3시간 전 알림'),
                            value: settings.enable3h,
                            onChanged: (v) => appState.updateSettings(settings.copyWith(enable3h: v)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('공유로 추가',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                          const SizedBox(height: 8),
                          Text(
                            '사람인/잡코리아/원티드 등의 공고에서 공유 버튼 → 마감노트 선택',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
