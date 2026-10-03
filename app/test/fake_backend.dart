import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:wearmony/api/api_client.dart';
import 'package:wearmony/state/session.dart';

/// A tiny in-test backend: maps "METHOD /path" to JSON responses.
class FakeBackend {
  FakeBackend(this.routes);

  final Map<String, Object? Function(http.Request request)> routes;
  final requests = <String>[];

  late final http.Client client = MockClient((request) async {
    final key = '${request.method} ${request.url.path}';
    requests.add(key);
    final handler = routes[key];
    if (handler == null) {
      return http.Response(
        jsonEncode({'error': 'not_found', 'message': 'Not found.'}),
        404,
      );
    }
    return http.Response(
      jsonEncode(handler(request)),
      200,
      headers: {'content-type': 'application/json'},
    );
  });

  Session session() {
    final api = ApiClient(
      baseUrl: 'http://localhost:8787',
      token: () async => 'dev.test',
      httpClient: client,
    );
    return Session(apiBaseUrl: 'http://localhost:8787', api: api);
  }
}

Map<String, Object?> config({String youcamMode = 'mock'}) => {
  'authMode': 'dev',
  'supabaseUrl': null,
  'supabasePublishableKey': null,
  'youcamMode': youcamMode,
  'dataMode': 'memory',
  'explainAvailable': false,
};

Map<String, Object?> eventJson({
  bool organizer = true,
  bool participant = false,
}) => {
  'id': 'e1',
  'name': 'Prom 2026',
  'template': 'prom',
  'joinCode': 'ABC234',
  'budgetPerPerson': 200,
  'budgetTotal': 300,
  'currency': 'EUR',
  'demo': false,
  'isOrganizer': organizer,
  'isParticipant': participant,
  'me': null,
};

Map<String, Object?> _color(String hex, String base) => {
  'hex': hex,
  'name': {'base': base, 'modifier': null, 'label': base},
};

Map<String, Object?> _person(
  String id,
  String name,
  String partner,
  String garmentHex, {
  bool rendered = false,
}) => {
  'userId': id,
  'displayName': name,
  'pairWith': partner,
  'pose': id == 'u2' ? 'seated' : 'standing',
  'isMe': false,
  'hasPhoto': true,
  'photoUrl': null,
  'look': {
    'garment': {
      'id': 'g-$id',
      'name': 'Dress $name',
      'price': 150,
      'colorHex': garmentHex,
    },
    'makeup': null,
    'hair': null,
    'locked': false,
    'total': 150,
  },
  'overBudget': false,
  'render': {
    'status': rendered ? 'success' : 'idle',
    'steps': [],
    'progress': rendered ? 1 : 0,
    'mock': true,
    'units': 0,
  },
};

Map<String, Object?> boardJson() {
  final nearMiss = {
    'scope': 'pair',
    'people': ['u1', 'u2'],
    'names': ['Maria', 'Ivan'],
    'subjects': ['outfit', 'outfit'],
    'colors': [_color('#E8A0B4', 'pink'), _color('#E39AB6', 'pink')],
    'relation': 'near_miss',
    'deltaE': 4.6,
    'score': 31,
    'partners': true,
    'sentence': '',
  };
  return {
    'event': eventJson(),
    'participants': [
      _person('u1', 'Maria', 'u2', '#E8A0B4', rendered: true),
      _person('u2', 'Ivan', 'u1', '#E39AB6'),
    ],
    'participantCount': 2,
    'renderedCount': 1,
    'lockedCount': 0,
    'budget': {
      'currency': 'EUR',
      'perPersonCap': 200,
      'totalCap': 300,
      'total': 300,
      'overTotal': false,
      'overBudgetCount': 0,
    },
    'units': {'used': 0, 'cap': 40, 'mode': 'mock'},
    'harmony': {
      'groupScore': 31,
      'weakest': nearMiss,
      'findings': [nearMiss],
      'counts': {
        'matched': 0,
        'near_miss': 1,
        'complementary': 0,
        'contrast': 0,
      },
      'withoutOutfit': [],
    },
  };
}

/// Suggestions for the near-miss in [boardJson]: Ivan (u2) switches to a matching tie.
Map<String, Object?> suggestionsJson() => {
  'target': (boardJson()['harmony'] as Map<String, Object?>)['weakest'],
  'suggestions': [
    {
      'userId': 'u2',
      'name': 'Ivan',
      'itemId': 'g-blush-tie',
      'itemName': 'Blush tie',
      'itemType': 'garment',
      'colorHex': '#E8A0B4',
      'imageUrl': null,
      'price': 35,
      'priceDelta': 0,
      'relationAfter': 'matched',
      'deltaEAfter': 0.4,
      'otherName': 'Maria',
      'groupScoreBefore': 31,
      'groupScoreAfter': 100,
      'warningsAfter': 0,
      'withinBudget': true,
    },
  ],
};
