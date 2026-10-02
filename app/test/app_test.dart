import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearmony/api/models.dart';
import 'package:wearmony/app.dart';
import 'package:wearmony/l10n/app_localizations.dart';
import 'package:wearmony/ui/motion.dart';
import 'package:wearmony/util/harmony_text.dart';
import 'package:wearmony/widgets/render_view.dart';

import 'fake_backend.dart';

Future<void> pumpApp(
  WidgetTester tester,
  FakeBackend backend, {
  String location = '/',
  Locale? locale,
}) async {
  final session = backend.session();
  if (locale != null) await session.setLocale(locale);
  await tester.pumpWidget(
    WearmonyApp(session: session, initialLocation: location),
  );
  await tester.pumpAndSettle();
}

/// Unmounts the app so periodic refresh timers stop before the test ends.
Future<void> unmount(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox());

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // Looping effects (aurora, shimmer, showcase) never settle; tests run with reduced motion.
    Motion.forceReduced = true;
  });

  testWidgets(
    'landing shows both roles, the demo and the simulated try-on notice',
    (tester) async {
      final backend = FakeBackend({
        'GET /api/config': (_) => config(),
        'GET /api/me/events': (_) => [],
      });
      await pumpApp(tester, backend, locale: const Locale('en'));

      expect(find.text('Try it on together.'), findsOneWidget);
      expect(find.text('Organize an event'), findsOneWidget);
      expect(find.text('Join with a code'), findsOneWidget);
      expect(find.text('Open the demo event'), findsOneWidget);
      expect(find.text('Try-on: simulated (mock mode)'), findsOneWidget);
    },
  );

  testWidgets('landing is translated to Bulgarian', (tester) async {
    final backend = FakeBackend({
      'GET /api/config': (_) => config(),
      'GET /api/me/events': (_) => [],
    });
    await pumpApp(tester, backend, locale: const Locale('bg'));

    expect(find.text('Организирай събитие'), findsOneWidget);
    expect(find.text('Влез с код'), findsOneWidget);
  });

  testWidgets('an invite link fills in the code and names the event', (
    tester,
  ) async {
    final backend = FakeBackend({
      'GET /api/config': (_) => config(),
      'GET /api/join/AB12CD': (_) => {
        'name': 'Prom 2026',
        'template': 'prom',
        'demo': false,
      },
    });
    await pumpApp(
      tester,
      backend,
      location: '/join/ab12cd',
      locale: const Locale('en'),
    );

    expect(find.text('AB12CD'), findsOneWidget);
    expect(find.textContaining('You are joining Prom 2026.'), findsOneWidget);
  });

  testWidgets(
    'the group board shows progress, budget and the near-miss between partners',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final backend = FakeBackend({
        'GET /api/config': (_) => config(),
        'GET /api/events/e1': (_) => eventJson(),
        'GET /api/events/e1/board': (_) => boardJson(),
      });
      await pumpApp(
        tester,
        backend,
        location: '/e/e1?tab=board',
        locale: const Locale('en'),
      );

      expect(find.text('1 of 2 rendered'), findsOneWidget);
      expect(find.text('31/100'), findsOneWidget);
      expect(
        find.textContaining(
          "Maria's pink and Ivan's pink are close but not the same shade (ΔE 4.6)",
        ),
        findsOneWidget,
      );
      expect(find.text('with Ivan'), findsOneWidget);
      expect(find.byTooltip('Seated'), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets('a render that did not apply the outfit is labeled honestly', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: RenderView(
              render: RenderState.fromJson({
                'status': 'success',
                'resultUrl': null,
                'mock': true,
                'checks': {'garmentApplied': false, 'drift': true},
              }),
              photoUrl: null,
              demo: false,
            ),
          ),
        ),
      ),
    );

    expect(
      find.textContaining('The outfit may not have been applied'),
      findsOneWidget,
    );
  });

  test('harmony sentences are localized from structured data', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('bg'));
    final finding = HarmonyFinding.fromJson(
      Map<String, dynamic>.from(boardJson()['harmony'] as Map)['weakest']
          as Map<String, dynamic>,
    );
    expect(
      findingSentence(l10n, finding),
      'Maria (розово) и Ivan (розово) са с близки, но не еднакви нюанси (ΔE 4.6). '
      'Едно до друго това може да изглежда като грешка: изберете точно същия цвят или ясно различен.',
    );
  });
}
