import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api/api_client.dart';
import 'app_scope.dart';
import 'l10n/app_localizations.dart';
import 'router.dart';
import 'theme.dart';

const _fallbackLocale = Locale('en');

class WearmonyApp extends StatefulWidget {
  const WearmonyApp({super.key, required this.api, this.locale, this.initialLocation = '/'});

  final ApiClient api;

  /// Forces a locale (tests, language switch). Null follows the device.
  final Locale? locale;
  final String initialLocation;

  @override
  State<WearmonyApp> createState() => _WearmonyAppState();
}

class _WearmonyAppState extends State<WearmonyApp> {
  late final GoRouter _router = buildRouter(initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      api: widget.api,
      child: MaterialApp.router(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        locale: widget.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // English for any language we do not translate (judges, visitors).
        localeResolutionCallback: (device, supported) => supported.firstWhere(
          (locale) => locale.languageCode == device?.languageCode,
          orElse: () => _fallbackLocale,
        ),
        routerConfig: _router,
      ),
    );
  }
}
