import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../state/app_state_scope.dart';
import '../ui/date_formatters.dart';
import '../widgets/deadline_editor_form.dart';

class DeadlineDetailScreen extends StatelessWidget {
  const DeadlineDetailScreen({required this.deadlineId, super.key});

  final String deadlineId;

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final deadline = appState.deadlines.firstWhere((d) => d.id == deadlineId);
    final shareText = [
      if (deadline.companyName.trim().isNotEmpty) deadline.companyName.trim(),
      if (deadline.jobTitle.trim().isNotEmpty) deadline.jobTitle.trim(),
      DateFormatters.ymd.format(deadline.deadlineAt),
      if (deadline.linkUrl.trim().isNotEmpty) deadline.linkUrl.trim(),
    ].join('\n');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${deadline.companyName} • ${DateFormatters.dDayLabel(deadline.deadlineAt)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (deadline.linkUrl.trim().isNotEmpty)
            IconButton(
              onPressed: () async {
                final uri = Uri.tryParse(deadline.linkUrl.trim());
                if (uri == null) return;
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              icon: const Icon(Icons.open_in_new),
              tooltip: '원본 공고 열기',
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final colorScheme = Theme.of(context).colorScheme;

              switch (value) {
                case 'edit':
                  if (!context.mounted) return;
                  messenger.showSnackBar(const SnackBar(content: Text('아래에서 수정 후 저장하세요.')));
                  return;
                case 'copy':
                  await Clipboard.setData(ClipboardData(text: shareText));
                  if (!context.mounted) return;
                  messenger.showSnackBar(const SnackBar(content: Text('복사 완료')));
                  return;
                case 'share':
                  await Share.share(shareText);
                  return;
                case 'delete':
                  if (!context.mounted) return;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: const Text('삭제 확인'),
                      content: const Text('정말 삭제하시겠습니까?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                          child: const Text('삭제'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await appState.deleteDeadline(deadline.id);
                    if (!context.mounted) return;
                    navigator.pop();
                  }
                  return;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('편집')),
              PopupMenuItem(value: 'copy', child: Text('복사')),
              PopupMenuItem(value: 'delete', child: Text('삭제')),
              PopupMenuItem(value: 'share', child: Text('공유')),
            ],
          ),
        ],
      ),
      body: DeadlineEditorForm(
        initial: deadline,
        submitLabel: '저장',
        allowDelete: true,
        onSubmit: (next) => appState.upsertDeadline(next),
        onDelete: () => appState.deleteDeadline(deadline.id),
      ),
    );
  }
}
