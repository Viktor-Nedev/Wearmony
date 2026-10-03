import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wearmony/api/models.dart';
import 'package:wearmony/features/event/group_insights.dart';
import 'package:wearmony/features/event/look_previews.dart';
import 'package:wearmony/app.dart';
import 'package:wearmony/l10n/app_localizations.dart';
import 'package:wearmony/ui/group_frame.dart';
import 'package:wearmony/ui/motion.dart';
import 'package:wearmony/util/format.dart';
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

      expect(find.text('Try it on together.'), findsWidgets);
      expect(find.text('Organize an event'), findsWidgets);
      expect(find.text('Join with a code'), findsWidgets);
      expect(find.text('Prom demo'), findsWidgets);
      expect(find.text('Theatre cast demo'), findsWidgets);
      expect(find.text('Try-on: simulated (mock mode)'), findsOneWidget);
    },
  );

  testWidgets('landing explains the three steps', (tester) async {
    final backend = FakeBackend({
      'GET /api/config': (_) => config(),
      'GET /api/me/events': (_) => [],
    });
    await pumpApp(tester, backend, locale: const Locale('en'));

    expect(find.text('How it works'), findsOneWidget);
    expect(find.text('Invite the group'), findsOneWidget);
    expect(find.text('Everyone tries on'), findsOneWidget);
    expect(find.text('See the group in harmony'), findsOneWidget);
  });

  testWidgets('landing names the YouCam APIs and answers questions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1300, 9000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend({
      'GET /api/config': (_) => config(),
      'GET /api/me/events': (_) => [],
    });
    await pumpApp(tester, backend, locale: const Locale('en'));

    expect(find.text('AI Clothes'), findsOneWidget);
    expect(find.text('AI Makeup'), findsOneWidget);
    expect(find.text('AI Hair Color'), findsOneWidget);
    expect(find.text('Private by design'), findsOneWidget);

    const answer =
        'It is a visual preview, not a fit guarantee. Fabric, light and cameras change how colors look on the night.';
    expect(find.text(answer), findsNothing);
    await tester.tap(find.text('Is the preview exact?'));
    await tester.pumpAndSettle();
    expect(find.text(answer), findsOneWidget);
  });

  testWidgets('an unknown link shows a way back home', (tester) async {
    final backend = FakeBackend({
      'GET /api/config': (_) => config(),
      'GET /api/me/events': (_) => [],
    });
    await pumpApp(
      tester,
      backend,
      location: '/no/such/page',
      locale: const Locale('en'),
    );

    expect(find.text('This page does not exist'), findsOneWidget);
    await tester.tap(find.text('Back to Wearmony'));
    await tester.pumpAndSettle();
    expect(find.text('Organize an event'), findsWidgets);
  });

  testWidgets('landing is translated to Bulgarian', (tester) async {
    final backend = FakeBackend({
      'GET /api/config': (_) => config(),
      'GET /api/me/events': (_) => [],
    });
    await pumpApp(tester, backend, locale: const Locale('bg'));

    expect(find.text('Организирай събитие'), findsWidgets);
    expect(find.text('Влез с код'), findsWidgets);
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
      expect(find.text('Recent activity'), findsOneWidget);
      expect(find.text('Ivan chose Dress Ivan'), findsOneWidget);
      expect(find.text('2 h ago'), findsOneWidget);
      expect(find.text('3 days ago'), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets('the harmony map links the near-miss pair', (tester) async {
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
      location: '/e/e1?tab=harmony',
      locale: const Locale('en'),
    );

    expect(find.text('Harmony map'), findsOneWidget);
    expect(find.text('ΔE 4.6'), findsOneWidget);
    expect(find.text('Near-miss'), findsWidgets);
    await unmount(tester);
  });

  testWidgets('the harmony tab suggests a swap that fixes the near-miss', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend({
      'GET /api/config': (_) => config(),
      'GET /api/events/e1': (_) => eventJson(),
      'GET /api/events/e1/board': (_) => boardJson(),
      'GET /api/events/e1/harmony/suggestions': (_) => suggestionsJson(),
    });
    await pumpApp(
      tester,
      backend,
      location: '/e/e1?tab=harmony',
      locale: const Locale('en'),
    );

    expect(find.text('How to fix it'), findsOneWidget);
    expect(find.text('Blush tie'), findsOneWidget);
    expect(find.textContaining('Matched with Maria'), findsOneWidget);
    expect(find.text('Same price'), findsOneWidget);
    // Ivan is someone else here, so the suggestion can be copied, not applied.
    expect(find.text('Copy suggestion'), findsOneWidget);
    expect(find.text('Switch to this'), findsNothing);
    await unmount(tester);
  });

  testWidgets('a person can switch to the suggested item from Together', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Map<String, Object?> board() {
      final data = boardJson();
      final people = (data['participants'] as List)
          .cast<Map<String, Object?>>();
      people[1]['isMe'] = true;
      return data;
    }

    String? putBody;
    final backend = FakeBackend({
      'GET /api/config': (_) => config(),
      'GET /api/events/e1': (_) => eventJson(participant: true),
      'GET /api/events/e1/board': (_) => board(),
      'GET /api/events/e1/harmony/suggestions': (_) => suggestionsJson(),
      'PUT /api/events/e1/look': (request) {
        putBody = request.body;
        return {'garmentId': 'g-blush-tie', 'locked': false, 'total': 35};
      },
    });
    await pumpApp(
      tester,
      backend,
      location: '/e/e1?tab=together',
      locale: const Locale('en'),
    );

    expect(find.text('How to fix it'), findsOneWidget);
    await tester.tap(find.text('Switch to this'));
    await tester.pumpAndSettle();
    expect(putBody, contains('g-blush-tie'));
    expect(
      find.text('Look updated. The harmony check already uses it.'),
      findsOneWidget,
    );
    await unmount(tester);
  });

  testWidgets('the group photo shows everyone with harmony and honest labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend({
      'GET /api/config': (_) => config(),
      'GET /api/events/e1/board': (_) => boardJson(),
    });
    await pumpApp(
      tester,
      backend,
      location: '/e/e1/frame',
      locale: const Locale('en'),
    );

    expect(find.text('Group photo'), findsOneWidget);
    expect(find.text('Maria'), findsOneWidget);
    expect(find.text('Ivan'), findsOneWidget);
    expect(find.text('Harmony 31/100'), findsOneWidget);
    expect(
      find.text('Virtual try-on preview, not a fit guarantee'),
      findsOneWidget,
    );
    // Tests run on the VM, where the image goes to the share sheet.
    expect(find.text('Share image'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('color bars in the budget and the group photo have height', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final board = Board.fromJson(boardJson());
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                BudgetBreakdown(board: board),
                GroupFrame(board: board, backdrop: FrameBackdrop.studio),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    for (final parent in [BudgetBreakdown, GroupFrame]) {
      final bars = find.descendant(
        of: find.byType(parent),
        matching: find.byWidgetPredicate(
          (w) => w is ColoredBox && w.child == null,
        ),
      );
      expect(bars, findsWidgets, reason: '$parent has color bars');
      for (final bar in bars.evaluate()) {
        expect((bar.renderObject! as RenderBox).size.height, greaterThan(0));
      }
    }
    await unmount(tester);
  });

  test('partners stand next to each other in the group photo', () {
    final data = boardJson();
    final people = (data['participants'] as List).cast<Map<String, Object?>>();
    people.insert(1, {
      ...people[1],
      'userId': 'u3',
      'displayName': 'Elena',
      'pairWith': null,
    });
    final order = GroupFrame.lineup(Board.fromJson(data));
    expect(order.map((p) => p.displayName), ['Maria', 'Ivan', 'Elena']);
  });

  testWidgets('a demo event offers a tour that jumps to each feature', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final backend = FakeBackend({
      'GET /api/config': (_) => config(),
      'GET /api/events/e1': (_) => {...eventJson(), 'demo': true},
      'GET /api/events/e1/board': (_) => boardJson(),
      'GET /api/events/e1/harmony/suggestions': (_) => suggestionsJson(),
    });
    await pumpApp(
      tester,
      backend,
      location: '/e/e1?tab=board',
      locale: const Locale('en'),
    );

    await tester.tap(find.text('Tour'));
    await tester.pumpAndSettle();
    expect(find.text('Take the tour'), findsOneWidget);
    expect(find.text('See everyone in one frame'), findsOneWidget);

    await tester.tap(find.text('Explore the harmony map'));
    await tester.pumpAndSettle();
    expect(find.text('Take the tour'), findsNothing);
    expect(find.text('Harmony map'), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('earlier previews can be compared and worn again', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Map<String, Object?> preview(String id, String name, bool current) => {
      'garment': {'id': id, 'name': name, 'price': 100, 'colorHex': '#E8A0B4'},
      'makeup': null,
      'hair': null,
      'imageUrl': null,
      'at': '2026-10-03T10:00:00Z',
      'current': current,
    };
    final looks = <String?>[];
    final backend = FakeBackend({
      'GET /api/config': (_) => config(),
      'GET /api/events/e1': (_) => {
        ...eventJson(participant: true),
        'me': {
          'userId': 'u1',
          'displayName': 'Maria',
          'consentAt': '2026-10-01T10:00:00Z',
          'hasPhoto': true,
          'photoUrl': null,
        },
      },
      'GET /api/events/e1/look': (_) => {
        'garmentId': 'g2',
        'total': 100,
        'render': {'status': 'success', 'steps': [], 'progress': 1},
      },
      'GET /api/events/e1/items': (_) => [
        {'id': 'g1', 'type': 'garment', 'name': 'Blush dress', 'price': 100},
        {'id': 'g2', 'type': 'garment', 'name': 'Navy suit', 'price': 100},
      ],
      'GET /api/events/e1/me/previews': (_) => [
        preview('g2', 'Navy suit', true),
        preview('g1', 'Blush dress', false),
      ],
      'PUT /api/events/e1/look': (request) {
        looks.add(request.body);
        return {
          'garmentId': 'g1',
          'total': 100,
          'render': {'status': 'idle'},
        };
      },
      'POST /api/events/e1/look/render': (_) => {
        'garmentId': 'g1',
        'total': 100,
        'render': {'status': 'success', 'steps': [], 'progress': 1},
      },
    });
    await pumpApp(
      tester,
      backend,
      location: '/e/e1?tab=myLook',
      locale: const Locale('en'),
    );

    expect(find.text('Your previews'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(PreviewStrip),
        matching: find.text('Blush dress'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Compare looks'), findsOneWidget);

    await tester.tap(find.text('Wear Blush dress again'));
    await tester.pumpAndSettle();
    expect(looks.single, contains('"garmentId":"g1"'));
    expect(backend.requests, contains('POST /api/events/e1/look/render'));
    await unmount(tester);
  });

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

  test('countdowns count calendar days in both languages', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final bg = await AppLocalizations.delegate.load(const Locale('bg'));
    final now = DateTime(2026, 10, 3, 23, 30);
    expect(countdownLabel(en, DateTime(2026, 10, 3), now: now), 'Today');
    expect(countdownLabel(en, DateTime(2026, 10, 4), now: now), 'in 1 day');
    expect(countdownLabel(en, DateTime(2027, 5, 23), now: now), 'in 232 days');
    expect(countdownLabel(en, DateTime(2026, 10, 1), now: now), '2 days ago');
    expect(countdownLabel(bg, DateTime(2026, 10, 13), now: now), 'след 10 дни');
  });

  test('activity times read naturally in both languages', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    final bg = await AppLocalizations.delegate.load(const Locale('bg'));
    final now = DateTime(2026, 10, 3, 12);
    String ago(Duration d, [AppLocalizations? l10n]) =>
        timeAgo(l10n ?? en, now.subtract(d), now: now);
    expect(ago(const Duration(seconds: 20)), 'just now');
    expect(ago(const Duration(minutes: 1)), '1 min ago');
    expect(ago(const Duration(minutes: 45)), '45 min ago');
    expect(ago(const Duration(hours: 5)), '5 h ago');
    expect(ago(const Duration(hours: 30)), 'yesterday');
    expect(ago(const Duration(days: 4)), '4 days ago');
    expect(ago(const Duration(hours: 3), bg), 'преди 3 ч');
  });

  test('event days travel as YYYY-MM-DD', () {
    expect(parseDay('2027-05-23'), DateTime(2027, 5, 23));
    expect(parseDay('soon'), isNull);
    expect(formatDay(DateTime(2027, 5, 3)), '2027-05-03');
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
