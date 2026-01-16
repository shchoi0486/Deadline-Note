import 'package:flutter/widgets.dart';

import 'app_state.dart';

class AppStateScope extends InheritedNotifier<AppState> {
  const AppStateScope({
    required AppState super.notifier,
    required super.child,
    super.key,
  });

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    if (scope?.notifier == null) {
      throw StateError('AppStateScope not found');
    }
    return scope!.notifier!;
  }
}

