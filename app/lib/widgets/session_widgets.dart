import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../state/session.dart';
import 'page_body.dart';

/// Shows [child] once the user is signed in; otherwise a spinner, an offline notice or sign-in.
class SessionGate extends StatelessWidget {
  const SessionGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    return switch (session.status) {
      SessionStatus.ready => child,
      SessionStatus.starting => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      SessionStatus.signInRequired => const SignInScreen(),
      SessionStatus.offline => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off, size: 40),
                const SizedBox(height: 12),
                Text(l10n.errorOffline, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(onPressed: session.start, child: Text(l10n.retry)),
              ],
            ),
          ),
        ),
      ),
    };
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit({required bool create}) async {
    final session = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      if (create) {
        final signedIn = await session.signUp(
          _email.text.trim(),
          _password.text,
        );
        if (!signedIn) setState(() => _message = l10n.checkEmail);
      } else {
        await session.signIn(_email.text.trim(), _password.text);
      }
    } catch (error) {
      setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.signInTitle),
        actions: const [LanguageMenu()],
      ),
      body: PageBody(
        children: [
          Text(l10n.signInExplain),
          const SizedBox(height: 16),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(labelText: l10n.emailLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(labelText: l10n.passwordLabel),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busy ? null : () => _submit(create: false),
            child: Text(l10n.signInButton),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy ? null : () => _submit(create: true),
            child: Text(l10n.signUpButton),
          ),
          if (_message != null) ...[
            const SizedBox(height: 16),
            Text(_message!),
          ],
        ],
      ),
    );
  }
}

/// Language switch: follow the device, English or Bulgarian.
class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.language,
      icon: const Icon(Icons.translate),
      onSelected: (code) => session.setLocale(Locale(code)),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'en', child: Text('English')),
        PopupMenuItem(value: 'bg', child: Text('Български')),
      ],
    );
  }
}

/// Says whether try-on is simulated or live.
class ApiStatusChip extends StatelessWidget {
  const ApiStatusChip({super.key});

  @override
  Widget build(BuildContext context) {
    final session = AppScope.of(context);
    final l10n = AppLocalizations.of(context);
    final config = session.config;
    final (label, icon) = config == null
        ? (l10n.apiStatusOffline, Icons.cloud_off)
        : config.isMock
        ? (l10n.apiStatusMock, Icons.science_outlined)
        : (l10n.apiStatusLive, Icons.cloud_done_outlined);
    return Center(
      child: Chip(avatar: Icon(icon, size: 18), label: Text(label)),
    );
  }
}
