import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_scope.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'state/session.dart';
import 'theme.dart';

import 'ui/confetti.dart';

const _fallbackLocale = Locale('en');

class WearmonyApp extends StatefulWidget {
  const WearmonyApp({
    super.key,
    required this.session,
    this.initialLocation = '/',
  });

  final Session session;
  final String initialLocation;

  @override
  State<WearmonyApp> createState() => _WearmonyAppState();
}

class _WearmonyAppState extends State<WearmonyApp> {
  late final GoRouter _router = buildRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void initState() {
    super.initState();
    if (widget.session.status == SessionStatus.starting) widget.session.start();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      session: widget.session,
      child: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) => MaterialApp.router(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          locale: widget.session.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // English for any language we do not translate (judges, visitors).
          localeResolutionCallback: (device, supported) => supported.firstWhere(
            (locale) => locale.languageCode == device?.languageCode,
            orElse: () => _fallbackLocale,
          ),
          routerConfig: _router,
          builder: (context, child) =>
              ConfettiCannon(child: child ?? const SizedBox.shrink()),
        ),
      ),
    );
  }
}
