import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'job_browser_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:deadline_note/l10n/app_localizations.dart';

import '../state/app_state_scope.dart';
import '../ui/date_formatters.dart';
import '../widgets/deadline_editor_form.dart';

class DeadlineDetailScreen extends StatelessWidget {
  const DeadlineDetailScreen({required this.deadlineId, super.key});

  final String deadlineId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = AppStateScope.of(context);
    final deadline = appState.deadlines.where((d) => d.id == deadlineId).firstOrNull;

    if (deadline == null) {
      return const SizedBox.shrink();
    }

    final shareText = [
      if (deadline.companyName.trim().isNotEmpty) deadline.companyName.trim(),
      if (deadline.jobTitle.trim().isNotEmpty) deadline.jobTitle.trim(),
      DateFormatters.ymd.format(deadline.deadlineAt),
      if (deadline.linkUrl.trim().isNotEmpty) deadline.linkUrl.trim(),
    ].join('\n');

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(
        title: Text(
          '${deadline.companyName} • ${DateFormatters.dDayLabel(l10n, deadline.deadlineAt)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (deadline.linkUrl.trim().isNotEmpty)
            IconButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) {
                      final uri = Uri.parse(deadline.linkUrl.trim());
                      final homeUrl = '${uri.scheme}://${uri.host}';
                      return JobBrowserScreen(
                        initialUrl: deadline.linkUrl.trim(),
                        homeUrl: homeUrl,
                        title: deadline.companyName,
                      );
                    },
                  ),
                );
              },
              icon: const Icon(Icons.open_in_browser_rounded),
              tooltip: l10n.openOriginalLink,
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final colorScheme = Theme.of(context).colorScheme;

              switch (value) {
                case 'edit':
                  if (!context.mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text(l10n.editGuide)));
                  return;
                case 'copy':
                  await Clipboard.setData(ClipboardData(text: shareText));
                  if (!context.mounted) return;
                  messenger.showSnackBar(SnackBar(content: Text(l10n.copyComplete)));
                  return;
                case 'share':
                  await Share.share(shareText);
                  return;
                case 'delete':
                  if (!context.mounted) return;
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(l10n.confirmDelete),
                      content: Text(l10n.confirmDeleteContent),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(false),
                          child: Text(l10n.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(true),
                          style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                          child: Text(l10n.delete),
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
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(l10n.edit)),
              PopupMenuItem(value: 'copy', child: Text(l10n.copy)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
              PopupMenuItem(value: 'share', child: Text(l10n.share)),
            ],
          ),
        ],
      ),
      body: DeadlineEditorForm(
        initial: deadline,
        submitLabel: l10n.save,
        allowDelete: true,
        onSubmit: (next, {silent = false}) => appState.upsertDeadline(next, incrementRevision: !silent),
        onDelete: () => appState.deleteDeadline(deadline.id),
      ),
    ),
  );
}
}
