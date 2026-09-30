import 'util/web_base_stub.dart' if (dart.library.js_interop) 'util/web_base_web.dart';

/// Build-time configuration, set with `--dart-define=KEY=value`.
class AppConfig {
  const AppConfig._();

  /// Base URL of the Wearmony backend (without the trailing `/api`).
  /// Android emulator: use http://10.0.2.2:8787 to reach the host machine.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8787');

  /// Public web address of the app, used in invite and vendor links shared from Android.
  static const publicWebUrl = String.fromEnvironment('PUBLIC_WEB_URL');
}

/// A shareable link to a page of the web app, e.g. appLink('/join/ABC123').
/// On the web it respects the base path (GitHub Pages serves the app under the repository name).
String appLink(String path) {
  final relative = path.startsWith('/') ? path.substring(1) : path;
  final base = webBaseUri();
  if (base != null) return base.resolve(relative).toString();
  final configured = AppConfig.publicWebUrl.isNotEmpty ? AppConfig.publicWebUrl : AppConfig.apiBaseUrl;
  return Uri.parse(configured.endsWith('/') ? configured : '$configured/').resolve(relative).toString();
}
