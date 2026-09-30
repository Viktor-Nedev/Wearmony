import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wearmony/api/api_client.dart';
import 'package:wearmony/api/models.dart';
import 'package:wearmony/app.dart';
import 'package:wearmony/l10n/app_localizations.dart';
import 'package:wearmony/widgets/tryon_status_view.dart';

ApiClient mockApi() => ApiClient(
      baseUrl: 'http://localhost:8787',
      httpClient: MockClient(
        (request) async => http.Response(jsonEncode({'ok': true, 'youcamMode': 'mock'}), 200),
      ),
    );

void main() {
  testWidgets('landing shows both roles and the mock API status', (tester) async {
    await tester.pumpWidget(WearmonyApp(api: mockApi(), locale: const Locale('en')));
    await tester.pumpAndSettle();

    expect(find.text('Try it on together.'), findsOneWidget);
    expect(find.text('Organize an event'), findsOneWidget);
    expect(find.text('Join with a code'), findsOneWidget);
    expect(find.text('API: mock mode'), findsOneWidget);
  });

  testWidgets('landing is translated to Bulgarian', (tester) async {
    await tester.pumpWidget(WearmonyApp(api: mockApi(), locale: const Locale('bg')));
    await tester.pumpAndSettle();

    expect(find.text('Организирай събитие'), findsOneWidget);
    expect(find.text('Влез с код'), findsOneWidget);
  });

  testWidgets('join link pre-fills the event code', (tester) async {
    await tester.pumpWidget(
      WearmonyApp(api: mockApi(), locale: const Locale('en'), initialLocation: '/join/ab12cd'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Join an event'), findsOneWidget);
    expect(find.text('AB12CD'), findsOneWidget);
  });

  testWidgets('a silent failure is explained and mock results are labeled', (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(
        body: TryOnStatusView(
          status: TryOnStatus(
            taskId: 't1',
            state: TaskState.failed,
            progress: 1,
            mock: true,
            failureReason: 'garment_not_applied',
          ),
        ),
      ),
    ));

    expect(find.text('Try-on failed'), findsOneWidget);
    expect(find.textContaining('The outfit was not applied'), findsOneWidget);
    expect(find.text('Simulated result (mock mode, no YouCam call)'), findsOneWidget);
  });
}
