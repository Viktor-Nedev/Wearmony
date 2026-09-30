import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'config.dart';
import 'state/session.dart';

void main() {
  // Clean web URLs (/v/<token> instead of /#/v/<token>); no effect on Android.
  usePathUrlStrategy();
  runApp(WearmonyApp(session: Session(apiBaseUrl: AppConfig.apiBaseUrl)));
}
