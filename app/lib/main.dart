import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'api/api_client.dart';
import 'app.dart';
import 'config.dart';

void main() {
  // Clean web URLs (/v/<token> instead of /#/v/<token>); no effect on Android.
  usePathUrlStrategy();
  runApp(WearmonyApp(api: ApiClient(baseUrl: AppConfig.apiBaseUrl)));
}
