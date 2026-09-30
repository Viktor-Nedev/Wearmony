import 'package:flutter/widgets.dart';

import 'api/api_client.dart';
import 'state/session.dart';

/// Makes the session available to the widget tree and rebuilds dependents when it changes.
class AppScope extends InheritedNotifier<Session> {
  const AppScope({super.key, required Session session, required super.child})
    : super(notifier: session);

  static Session of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope above this context');
    return scope!.notifier!;
  }

  static ApiClient api(BuildContext context) => of(context).api;
}
