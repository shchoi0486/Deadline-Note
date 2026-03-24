import 'package:flutter/material.dart';
import 'package:deadline_note/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state_scope.dart';
import '../widgets/ad_placeholder.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final settings = appState.settings;
    final l10n = AppLocalizations.of(context)!;

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 일정/현황 화면과 동일한 커스텀 헤더 구조 적용
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
                                  l10n.tabSettings,
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

                    // Right: Actions
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // 1. 마감 알림 섹션
                  _buildSettingsCard(
                    context,
                    title: l10n.settingsDeadlineAlarm,
                    children: [
                      _buildSwitchItem(
                        context,
                        title: l10n.settingsD3Alarm,
                        value: settings.enableD3,
                        onChanged: (v) => appState.updateSettings(settings.copyWith(enableD3: v)),
                      ),
                      _buildSwitchItem(
                        context,
                        title: l10n.settingsD1Alarm,
                        value: settings.enableD1,
                        onChanged: (v) => appState.updateSettings(settings.copyWith(enableD1: v)),
                      ),
                      _buildSwitchItem(
                        context,
                        title: l10n.settings3hAlarm,
                        value: settings.enable3h,
                        onChanged: (v) => appState.updateSettings(settings.copyWith(enable3h: v)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 2. 다국어 및 공휴일 설정 섹션
                  _buildSettingsCard(
                    context,
                    title: l10n.settingsHoliday,
                    children: [
                      _buildDropdownItem(
                        context,
                        label: l10n.settingsLanguage,
                        value: settings.localeCode,
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.holidayAuto)),
                          DropdownMenuItem(value: 'ko', child: Text(l10n.languageKorean)),
                          DropdownMenuItem(value: 'en', child: Text(l10n.languageEnglish)),
                          DropdownMenuItem(value: 'ja', child: Text(l10n.languageJapanese)),
                          DropdownMenuItem(value: 'zh', child: Text(l10n.languageChinese)),
                          DropdownMenuItem(value: 'hi', child: Text(l10n.languageHindi)),
                        ],
                        onChanged: (v) => appState.updateSettings(settings.copyWith(localeCode: v)),
                      ),
                      _buildDropdownItem(
                        context,
                        label: l10n.settingsHolidayCountry,
                        value: settings.holidayCountryCode,
                        items: [
                          DropdownMenuItem(value: null, child: Text(l10n.holidayAuto)),
                          DropdownMenuItem(value: 'KR', child: Text(l10n.countryKorea)),
                          DropdownMenuItem(value: 'US', child: Text(l10n.countryUS)),
                          DropdownMenuItem(value: 'JP', child: Text(l10n.countryJapan)),
                          DropdownMenuItem(value: 'CN', child: Text(l10n.countryChina)),
                          DropdownMenuItem(value: 'GB', child: Text(l10n.countryUK)),
                          DropdownMenuItem(value: 'DE', child: Text(l10n.countryGermany)),
                          DropdownMenuItem(value: 'FR', child: Text(l10n.countryFrance)),
                          DropdownMenuItem(value: 'CA', child: Text(l10n.countryCanada)),
                          DropdownMenuItem(value: 'AU', child: Text(l10n.countryAustralia)),
                        ],
                        onChanged: (v) => appState.updateSettings(settings.copyWith(holidayCountryCode: v)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.settingsHolidayDesc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 3. SERIESSNAP 앱 홍보 섹션
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 8),
                    child: Text(
                      l10n.settingsPromoFooter,
                      style: TextStyle(
                        fontSize: 14,
                        color: cs.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cs.primary.withOpacity(0.08), cs.secondary.withOpacity(0.08)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.primary.withOpacity(0.1)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () async {
                          final url = Uri.parse('https://play.google.com/store/apps/details?id=com.seriessnap.fortunealarm');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    'https://play-lh.googleusercontent.com/LI8H8SO8jaVWnXo5_NfsUx2P14XxSsek7fmDmCpQdf-2IsfTbKX1oBbNJQ8XbgN6O95XRZi42c5qAX4I8fji=s120-rw',
                                    errorBuilder: (context, error, stackTrace) => Icon(Icons.alarm, color: cs.primary, size: 22),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          l10n.settingsPromoTitle,
                                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 16,
                                              ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: cs.primary,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'NEW',
                                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.settingsPromoDesc,
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: cs.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 14, color: cs.onSurfaceVariant.withOpacity(0.4)),
                            ],
                          ),
                        ),
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

  Widget _buildSettingsCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 6),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchItem(BuildContext context,
      {required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: Theme.of(context).colorScheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownItem(BuildContext context,
      {required String label, required dynamic value, required List<DropdownMenuItem<dynamic>> items, required ValueChanged<dynamic> onChanged}) {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          DropdownButton<dynamic>(
            value: value,
            underline: const SizedBox(),
            isDense: true,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
            items: items,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
