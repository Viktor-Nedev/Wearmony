import 'package:flutter/widgets.dart';

import 'api/api_client.dart';

/// Makes app-wide services available to the widget tree (and replaceable in tests).
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.api, required super.child});

  final ApiClient api;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this context');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => api != oldWidget.api;
}
