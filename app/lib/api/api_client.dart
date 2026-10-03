import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'models.dart';

/// An error from the backend, with its stable code (see api/http/context.ts).
class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.statusCode, this.details});

  final String code;
  final String message;
  final int? statusCode;
  final Object? details;

  @override
  String toString() => 'ApiException($statusCode, $code): $message';
}

/// Talks to the Wearmony backend. The app never calls YouCam or Supabase data directly.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required Future<String?> Function() token,
    http.Client? httpClient,
  }) : _base = Uri.parse(baseUrl),
       _token = token,
       _http = httpClient ?? http.Client();

  final Uri _base;
  final Future<String?> Function() _token;
  final http.Client _http;

  /// Media URLs may be relative to the API (memory mode) or absolute (Supabase).
  String resolveUrl(String url) => _base.resolve(url).toString();

  Uri _uri(String path) => _base.resolve('/api/$path');

  // Public -------------------------------------------------------------------

  Future<AppConfigInfo> config() async =>
      AppConfigInfo.fromJson(await _send('GET', 'config', auth: false));

  Future<InclusionResults> inclusion() async =>
      InclusionResults.fromJson(await _send('GET', 'inclusion', auth: false));

  Future<JoinPreview> joinPreview(String code) async => JoinPreview.fromJson(
    await _send('GET', 'join/${Uri.encodeComponent(code)}', auth: false),
  );

  Future<VendorView> vendorView(String token) async => VendorView.fromJson(
    await _send('GET', 'vendor/${Uri.encodeComponent(token)}', auth: false),
  );

  Future<CatalogItem> vendorAddItem(String token, Json item) async =>
      CatalogItem.fromJson(
        await _send(
          'POST',
          'vendor/${Uri.encodeComponent(token)}/items',
          body: item,
          auth: false,
        ),
      );

  Future<CatalogItem> vendorSetItemImage(
    String token,
    String itemId,
    Uint8List bytes,
  ) async => CatalogItem.fromJson(
    await _sendBytes(
      'PUT',
      'vendor/${Uri.encodeComponent(token)}/items/$itemId/image',
      bytes,
      auth: false,
    ),
  );

  // Events -------------------------------------------------------------------

  Future<List<EventInfo>> myEvents() async =>
      ((await _send('GET', 'me/events')) as List)
          .whereType<Json>()
          .map(EventInfo.fromJson)
          .toList();

  Future<EventInfo> createEvent({
    required String name,
    required EventTemplate template,
    double? budgetPerPerson,
    double? budgetTotal,
    DateTime? eventDate,
  }) async => EventInfo.fromJson(
    await _send(
      'POST',
      'events',
      body: {
        'name': name,
        'template': template.name,
        'budgetPerPerson': budgetPerPerson,
        'budgetTotal': budgetTotal,
        if (eventDate != null) 'eventDate': formatDay(eventDate),
      },
    ),
  );

  /// The visitor's demo event of this kind (a prom or a theatre cast), created once.
  Future<EventInfo> createDemo({
    EventTemplate template = EventTemplate.prom,
  }) async => EventInfo.fromJson(
    await _send(
      'POST',
      template == EventTemplate.prom
          ? 'demo'
          : 'demo?template=${template.name}',
    ),
  );

  Future<EventInfo> event(String eventId) async =>
      EventInfo.fromJson(await _send('GET', 'events/$eventId'));

  Future<EventInfo> updateEvent(
    String eventId, {
    String? name,
    double? budgetPerPerson,
    double? budgetTotal,
    bool clearBudgets = false,
    DateTime? eventDate,
    bool clearDate = false,
  }) async {
    final body = <String, dynamic>{
      if (name != null) 'name': name,
      if (budgetPerPerson != null || clearBudgets)
        'budgetPerPerson': budgetPerPerson,
      if (budgetTotal != null || clearBudgets) 'budgetTotal': budgetTotal,
      if (eventDate != null) 'eventDate': formatDay(eventDate),
      if (clearDate && eventDate == null) 'eventDate': null,
    };
    return EventInfo.fromJson(
      await _send('PATCH', 'events/$eventId', body: body),
    );
  }

  Future<void> deleteEvent(String eventId) =>
      _send('DELETE', 'events/$eventId');

  Future<String> join(String code, String displayName) async =>
      ((await _send(
                'POST',
                'join',
                body: {'code': code, 'displayName': displayName},
              ))
              as Json)['eventId']
          as String;

  Future<void> leaveEvent(String eventId) =>
      _send('DELETE', 'events/$eventId/me');

  Future<void> removeParticipant(String eventId, String userId) =>
      _send('DELETE', 'events/$eventId/participants/$userId');

  Future<int> deleteAllMyData() async =>
      (((await _send('DELETE', 'me')) as Json)['left'] as num).toInt();

  // Me -----------------------------------------------------------------------

  Future<Participant> updateMe(
    String eventId, {
    String? displayName,
    Pose? pose,
    String? pairWith,
    bool unpair = false,
  }) async => Participant.fromJson(
    await _send(
      'PATCH',
      'events/$eventId/me',
      body: {
        if (displayName != null) 'displayName': displayName,
        if (pose != null) 'pose': pose.name,
        if (pairWith != null || unpair) 'pairWith': pairWith,
      },
    ),
  );

  Future<Participant> consent(String eventId) async =>
      Participant.fromJson(await _send('POST', 'events/$eventId/me/consent'));

  Future<Participant> uploadPhoto(
    String eventId,
    Uint8List bytes,
    Pose pose,
  ) async => Participant.fromJson(
    await _sendBytes(
      'PUT',
      'events/$eventId/me/photo?pose=${pose.name}',
      bytes,
    ),
  );

  Future<Participant> deletePhoto(String eventId) async =>
      Participant.fromJson(await _send('DELETE', 'events/$eventId/me/photo'));

  // Catalogue ----------------------------------------------------------------

  Future<List<CatalogItem>> items(String eventId) async =>
      ((await _send('GET', 'events/$eventId/items')) as List)
          .whereType<Json>()
          .map(CatalogItem.fromJson)
          .toList();

  Future<CatalogItem> addItem(String eventId, Json item) async =>
      CatalogItem.fromJson(
        await _send('POST', 'events/$eventId/items', body: item),
      );

  Future<CatalogItem> setItemImage(
    String eventId,
    String itemId,
    Uint8List bytes,
  ) async => CatalogItem.fromJson(
    await _sendBytes('PUT', 'events/$eventId/items/$itemId/image', bytes),
  );

  Future<void> deleteItem(String eventId, String itemId) =>
      _send('DELETE', 'events/$eventId/items/$itemId');

  // Look and try-on -----------------------------------------------------------

  Future<Look> look(String eventId) async =>
      Look.fromJson(await _send('GET', 'events/$eventId/look'));

  /// Looks already previewed on the current photo, newest first.
  Future<List<PreviewLook>> previews(String eventId) async =>
      ((await _send('GET', 'events/$eventId/me/previews')) as List)
          .whereType<Json>()
          .map(PreviewLook.fromJson)
          .toList();

  /// Pass only the slots to change; `null` in [clear] removes that item.
  Future<Look> setLook(
    String eventId, {
    String? garmentId,
    String? makeupId,
    String? hairId,
    Set<ItemType> clear = const {},
  }) async => Look.fromJson(
    await _send(
      'PUT',
      'events/$eventId/look',
      body: {
        if (garmentId != null || clear.contains(ItemType.garment))
          'garmentId': garmentId,
        if (makeupId != null || clear.contains(ItemType.makeup))
          'makeupId': makeupId,
        if (hairId != null || clear.contains(ItemType.hair)) 'hairId': hairId,
      },
    ),
  );

  Future<Look> render(String eventId, {bool retry = false}) async =>
      Look.fromJson(
        await _send(
          'POST',
          'events/$eventId/look/render',
          body: {'retry': retry},
        ),
      );

  Future<Look> lock(String eventId, bool locked) async => Look.fromJson(
    await _send('POST', 'events/$eventId/look/lock', body: {'locked': locked}),
  );

  // Group ----------------------------------------------------------------------

  Future<Board> board(String eventId) async =>
      Board.fromJson(await _send('GET', 'events/$eventId/board'));

  /// Catalogue swaps that remove the group's weakest near-miss, or with [user]
  /// the weakest near-miss involving that person.
  Future<FixSuggestions> suggestions(
    String eventId, {
    String? user,
    String? withUser,
  }) async {
    final query = {'user': ?user, 'with': ?withUser};
    final path = Uri(
      path: 'events/$eventId/harmony/suggestions',
      queryParameters: query.isEmpty ? null : query,
    ).toString();
    return FixSuggestions.fromJson(await _send('GET', path));
  }

  Future<String> explainHarmony(String eventId, String language) async =>
      ((await _send(
                'POST',
                'events/$eventId/harmony/explain',
                body: {'language': language},
              ))
              as Json)['text']
          as String;

  Future<VendorLinkCreated> createVendorLink(
    String eventId, {
    required String scope,
    String? userId,
    String? vendorName,
    int hours = 168,
  }) async => VendorLinkCreated.fromJson(
    await _send(
      'POST',
      'events/$eventId/vendor-links',
      body: {
        'scope': scope,
        if (userId != null) 'userId': userId,
        if (vendorName != null && vendorName.isNotEmpty)
          'vendorName': vendorName,
        'hours': hours,
      },
    ),
  );

  // Transport ------------------------------------------------------------------

  Future<Map<String, String>> _headers(bool auth, {String? contentType}) async {
    final headers = <String, String>{
      if (contentType != null) 'Content-Type': contentType,
    };
    if (auth) {
      final token = await _token();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<dynamic> _send(
    String method,
    String path, {
    Object? body,
    bool auth = true,
  }) async {
    final request = http.Request(method, _uri(path));
    request.headers.addAll(
      await _headers(
        auth,
        contentType: body == null ? null : 'application/json',
      ),
    );
    if (body != null) request.body = jsonEncode(body);
    return _decode(await http.Response.fromStream(await _http.send(request)));
  }

  Future<dynamic> _sendBytes(
    String method,
    String path,
    Uint8List bytes, {
    bool auth = true,
  }) async {
    final request = http.Request(method, _uri(path));
    request.headers.addAll(
      await _headers(auth, contentType: _imageType(bytes)),
    );
    request.bodyBytes = bytes;
    return _decode(await http.Response.fromStream(await _http.send(request)));
  }

  static String _imageType(Uint8List bytes) =>
      bytes.length > 4 &&
          bytes[0] == 0x89 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x4E &&
          bytes[3] == 0x47
      ? 'image/png'
      : 'image/jpeg';

  dynamic _decode(http.Response response) {
    final text = utf8.decode(response.bodyBytes);
    final json = text.isEmpty ? null : jsonDecode(text);
    if (response.statusCode >= 200 && response.statusCode < 300) return json;
    if (json is Json) {
      throw ApiException(
        json['error'] as String? ?? 'error',
        json['message'] as String? ?? 'Something went wrong.',
        statusCode: response.statusCode,
        details: json['details'],
      );
    }
    throw ApiException(
      'error',
      'Something went wrong.',
      statusCode: response.statusCode,
    );
  }
}
