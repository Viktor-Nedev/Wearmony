import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Raised when the backend needs a real account (anonymous sign-in is off).
class SignInRequired implements Exception {
  const SignInRequired([this.message]);

  final String? message;
}

/// Who the user is, as far as the backend is concerned.
abstract class AuthService {
  /// Makes sure there is a session; throws [SignInRequired] if one cannot be created silently.
  Future<void> ensureSignedIn();

  Future<String?> token();

  bool get canUseEmail;

  String? get email;

  Future<void> signInWithEmail(String email, String password);

  /// Returns false when the account still has to be confirmed by email.
  Future<bool> signUpWithEmail(String email, String password);
}

/// Local development and the no-account demo: a random id kept on this device.
class DevAuthService implements AuthService {
  static const _key = 'wearmony.devUserId';
  String? _userId;

  @override
  Future<void> ensureSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString(_key);
    if (_userId == null) {
      _userId = newUuid();
      await prefs.setString(_key, _userId!);
    }
  }

  @override
  Future<String?> token() async => _userId == null ? null : 'dev.$_userId';

  @override
  bool get canUseEmail => false;

  @override
  String? get email => null;

  @override
  Future<void> signInWithEmail(String email, String password) async {}

  @override
  Future<bool> signUpWithEmail(String email, String password) async => false;
}

/// Supabase Auth: anonymous sessions by default, email and password when needed.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService({required this.url, required this.publishableKey});

  final String url;
  final String publishableKey;

  supa.GoTrueClient get _auth => supa.Supabase.instance.client.auth;

  @override
  Future<void> ensureSignedIn() async {
    await supa.Supabase.initialize(url: url, publishableKey: publishableKey);
    if (_auth.currentSession != null) return;
    try {
      await _auth.signInAnonymously();
    } on supa.AuthException catch (error) {
      throw SignInRequired(error.message);
    }
  }

  @override
  Future<String?> token() async {
    final session = _auth.currentSession;
    if (session == null) return null;
    if (session.isExpired) {
      return (await _auth.refreshSession()).session?.accessToken;
    }
    return session.accessToken;
  }

  @override
  bool get canUseEmail => true;

  @override
  String? get email => _auth.currentUser?.email;

  @override
  Future<void> signInWithEmail(String email, String password) async {
    await _auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<bool> signUpWithEmail(String email, String password) async {
    final response = await _auth.signUp(email: email, password: password);
    return response.session != null;
  }
}

/// Random version 4 UUID.
String newUuid([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
