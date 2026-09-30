import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wearmony/api/api_client.dart';
import 'package:wearmony/api/models.dart';

http.Response jsonResponse(Object body, [int status = 200]) =>
    http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json'});

Map<String, dynamic> statusJson(String state, {double progress = 0, Map<String, String>? failure}) => {
      'taskId': 't1',
      'state': state,
      'progress': progress,
      'resultUrl': null,
      'failure': failure,
      'mock': true,
    };

void main() {
  test('reads health and mock mode', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8787',
      httpClient: MockClient((request) async {
        expect(request.url.toString(), 'http://localhost:8787/api/health');
        return jsonResponse({'ok': true, 'youcamMode': 'mock'});
      }),
    );
    final health = await api.health();
    expect(health.ok, isTrue);
    expect(health.isMock, isTrue);
  });

  test('starts a try-on with the expected body', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8787',
      httpClient: MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/tryon');
        expect(jsonDecode(request.body), {'kind': 'apparel', 'photoRef': 'p.jpg', 'itemRef': 'i.jpg'});
        return jsonResponse({'taskId': 't1', 'mock': true}, 202);
      }),
    );
    final id = await api.startTryOn(kind: TryOnKind.apparel, photoRef: 'p.jpg', itemRef: 'i.jpg');
    expect(id, 't1');
  });

  test('polls until the task is final', () async {
    final states = ['queued', 'running', 'failed'];
    var call = 0;
    final api = ApiClient(
      baseUrl: 'http://localhost:8787',
      httpClient: MockClient((request) async => jsonResponse(statusJson(
            states[call++],
            failure: call == 3 ? {'reason': 'garment_not_applied', 'message': 'x'} : null,
          ))),
    );
    final updates = await api.watchTryOn('t1', interval: Duration.zero).toList();
    expect(updates.map((s) => s.state), [TaskState.queued, TaskState.running, TaskState.failed]);
    expect(updates.last.failureReason, 'garment_not_applied');
  });

  test('gives up after the timeout', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8787',
      httpClient: MockClient((request) async => jsonResponse(statusJson('running', progress: 0.5))),
    );
    expect(
      api.watchTryOn('t1', interval: Duration.zero, timeout: Duration.zero).toList(),
      throwsA(isA<TryOnTimeoutException>()),
    );
  });

  test('turns error responses into ApiException', () async {
    final api = ApiClient(
      baseUrl: 'http://localhost:8787',
      httpClient: MockClient((request) async => jsonResponse({'error': 'unknown_task'}, 404)),
    );
    expect(api.tryOnStatus('nope'), throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404)));
  });
}
