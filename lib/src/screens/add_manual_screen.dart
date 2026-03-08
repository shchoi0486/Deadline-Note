import 'package:flutter/material.dart';
import 'package:deadline_note/l10n/app_localizations.dart';

import '../state/app_state_scope.dart';
import '../widgets/deadline_editor_form.dart';

class AddManualScreen extends StatelessWidget {
  const AddManualScreen({this.prefillUrl, this.initialDate, super.key});

  final String? prefillUrl;
  final DateTime? initialDate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appState = AppStateScope.of(context);
    var blank = appState.createBlankDeadline();
    
    if (initialDate != null) {
      final d = initialDate!;
      blank = blank.copyWith(deadlineAt: DateTime(d.year, d.month, d.day, 23, 59));
    }
    
    final initial = (prefillUrl == null || prefillUrl!.trim().isEmpty) ? blank : blank.copyWith(linkUrl: prefillUrl!.trim());

    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(title: Text(l10n.addMethodManual)),
        body: DeadlineEditorForm(
          initial: initial,
          submitLabel: l10n.save,
          onSubmit: (next, {silent = false}) => appState.upsertDeadline(next, incrementRevision: !silent),
        ),
      ),
    );
  }
}
