import 'package:flutter/material.dart';

import '../state/app_state_scope.dart';
import '../widgets/deadline_editor_form.dart';

class AddManualScreen extends StatelessWidget {
  const AddManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final blank = appState.createBlankDeadline();

    return Scaffold(
      appBar: AppBar(title: const Text('직접 추가')),
      body: DeadlineEditorForm(
        initial: blank,
        submitLabel: '저장',
        onSubmit: (next) => appState.upsertDeadline(next),
      ),
    );
  }
}

