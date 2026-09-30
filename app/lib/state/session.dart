import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/models.dart';
import '../auth/auth_service.dart';

enum SessionStatus { starting, ready, signInRequired, offline }

typedef AuthFactory = AuthService Function(AppConfigInfo config);

AuthService defaultAuthFactory(AppConfigInfo config) =>
    config.authMode == 'supabase' &&
        config.supabaseUrl != null &&
        config.supabasePublishableKey != null
    ? SupabaseAuthService(
        url: config.supabaseUrl!,
        publishableKey: config.supabasePublishableKey!,
      )
    : DevAuthService();

/// App-wide state: backend config, the signed-in user and the chosen language.
class Session extends ChangeNotifier {
  Session({
    required String apiBaseUrl,
    this.authFactory = defaultAuthFactory,
    ApiClient? api,
  }) {
    this.api =
        api ??
        ApiClient(baseUrl: apiBaseUrl, token: () async => _auth?.token());
  }

  static const _localeKey = 'wearmony.locale';

  final AuthFactory authFactory;
  late final ApiClient api;

  SessionStatus status = SessionStatus.starting;
  AppConfigInfo? config;
  String? signInMessage;
  Locale? locale;
  AuthService? _auth;

  AuthService? get auth => _auth;

  Future<void> start() async {
    status = SessionStatus.starting;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_localeKey);
      if (saved != null) locale = Locale(saved);
    } catch (_) {
      // Preferences are a convenience; the app works without them.
    }
    try {
      config = await api.config();
      _auth = authFactory(config!);
      await _auth!.ensureSignedIn();
      status = SessionStatus.ready;
    } on SignInRequired catch (error) {
      signInMessage = error.message;
      status = SessionStatus.signInRequired;
    } catch (_) {
      status = SessionStatus.offline;
    }
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    await _auth!.signInWithEmail(email, password);
    status = SessionStatus.ready;
    notifyListeners();
  }

  /// Returns false when the email still has to be confirmed.
  Future<bool> signUp(String email, String password) async {
    final signedIn = await _auth!.signUpWithEmail(email, password);
    if (signedIn) {
      status = SessionStatus.ready;
      notifyListeners();
    }
    return signedIn;
  }

  Future<void> setLocale(Locale? value) async {
    locale = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(_localeKey);
      } else {
        await prefs.setString(_localeKey, value.languageCode);
      }
    } catch (_) {}
  }
}
