/// Build-time configuration, set with `--dart-define=KEY=value`.
class AppConfig {
  const AppConfig._();

  /// Base URL of the Wearmony backend (without the trailing `/api`).
  /// Android emulator: use http://10.0.2.2:8787 to reach the host machine.
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8787',
  );
}
