import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wearmony/api/api_client.dart';
import 'package:wearmony/api/models.dart';

http.Response jsonResponse(Object? body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

ApiClient client(
  Future<http.Response> Function(http.Request request) handler, {
  String? token = 'dev.abc',
}) => ApiClient(
  baseUrl: 'http://localhost:8787',
  token: () async => token,
  httpClient: MockClient(handler),
);

void main() {
  test('reads the public config without a token', () async {
    final api = client((request) async {
      expect(request.url.toString(), 'http://localhost:8787/api/config');
      expect(request.headers.containsKey('Authorization'), isFalse);
      return jsonResponse({
        'authMode': 'dev',
        'youcamMode': 'mock',
        'dataMode': 'memory',
        'explainAvailable': true,
      });
    });
    final config = await api.config();
    expect(config.isMock, isTrue);
    expect(config.explainAvailable, isTrue);
  });

  test('sends the bearer token and JSON body when creating an event', () async {
    final api = client((request) async {
      expect(request.method, 'POST');
      expect(request.headers['Authorization'], 'Bearer dev.abc');
      expect(jsonDecode(request.body), {
        'name': 'Prom',
        'template': 'prom',
        'budgetPerPerson': 250.0,
        'budgetTotal': null,
      });
      return jsonResponse({
        'id': 'e1',
        'name': 'Prom',
        'template': 'prom',
        'joinCode': 'ABC234',
        'currency': 'EUR',
        'isOrganizer': true,
        'isParticipant': false,
      }, 201);
    });
    final event = await api.createEvent(
      name: 'Prom',
      template: EventTemplate.prom,
      budgetPerPerson: 250,
    );
    expect(event.joinCode, 'ABC234');
    expect(event.isOrganizer, isTrue);
  });

  test('uploads a photo as raw bytes with the detected image type', () async {
    final png = Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);
    final api = client((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/events/e1/me/photo');
      expect(request.url.queryParameters['pose'], 'seated');
      expect(request.headers['Content-Type'], 'image/png');
      expect(request.bodyBytes, png);
      return jsonResponse({
        'userId': 'u1',
        'displayName': 'Ana',
        'hasPhoto': true,
        'pose': 'seated',
      });
    });
    final me = await api.uploadPhoto('e1', png, Pose.seated);
    expect(me.pose, Pose.seated);
  });

  test(
    'only sends the look slots being changed, with explicit nulls to clear',
    () async {
      final bodies = <Object?>[];
      final api = client((request) async {
        bodies.add(jsonDecode(request.body));
        return jsonResponse({
          'locked': false,
          'total': 0,
          'currency': 'EUR',
          'render': {'status': 'empty'},
        });
      });
      await api.setLook('e1', garmentId: 'g1');
      await api.setLook('e1', clear: {ItemType.hair});
      expect(bodies, [
        {'garmentId': 'g1'},
        {'hairId': null},
      ]);
    },
  );

  test('turns API errors into ApiException with code and details', () async {
    final api = client(
      (request) async => jsonResponse({
        'error': 'photo_rejected',
        'message': 'This photo cannot be used for try-on.',
        'details': {
          'issues': ['too_small'],
        },
      }, 422),
    );
    expect(
      api.uploadPhoto('e1', Uint8List.fromList([0xFF, 0xD8]), Pose.standing),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'photo_rejected')
            .having((e) => e.statusCode, 'status', 422),
      ),
    );
  });

  test('resolves API-relative media URLs and keeps absolute ones', () {
    final api = client((request) async => jsonResponse(null));
    expect(
      api.resolveUrl('/api/media?path=x'),
      'http://localhost:8787/api/media?path=x',
    );
    expect(
      api.resolveUrl('https://cdn.example/a.jpg'),
      'https://cdn.example/a.jpg',
    );
  });
}
