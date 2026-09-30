import 'package:flutter/foundation.dart';

/// Build-time configuration, set with `--dart-define=KEY=value`.
class AppConfig {
  const AppConfig._();

  /// Base URL of the Wearmony backend (without the trailing `/api`).
  /// Android emulator: use http://10.0.2.2:8787 to reach the host machine.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8787',
  );

  /// Public web address used in invite and vendor links shared from the Android app.
  static const publicWebUrl = String.fromEnvironment('PUBLIC_WEB_URL');
}

/// A shareable link to a page of the web app, e.g. appLink('/join/ABC123').
String appLink(String path) {
  if (kIsWeb) return Uri.base.resolve(path).toString();
  final base = AppConfig.publicWebUrl.isNotEmpty
      ? AppConfig.publicWebUrl
      : AppConfig.apiBaseUrl;
  return Uri.parse(base).resolve(path).toString();
}
