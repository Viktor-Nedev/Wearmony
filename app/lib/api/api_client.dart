import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class TryOnTimeoutException implements Exception {
  const TryOnTimeoutException(this.taskId);

  final String taskId;
}

/// Talks to the Wearmony backend. The client never calls YouCam directly.
class ApiClient {
  ApiClient({required String baseUrl, http.Client? httpClient})
      : _base = Uri.parse(baseUrl),
        _http = httpClient ?? http.Client();

  final Uri _base;
  final http.Client _http;

  Uri _uri(String path) => _base.resolve('/api/$path');

  Future<ApiHealth> health() async => ApiHealth.fromJson(await _get('health'));

  Future<String> startTryOn({
    required TryOnKind kind,
    required String photoRef,
    required String itemRef,
  }) async {
    final json = await _post('tryon', {
      'kind': kind.name,
      'photoRef': photoRef,
      'itemRef': itemRef,
    });
    return json['taskId'] as String;
  }

  Future<TryOnStatus> tryOnStatus(String taskId) async =>
      TryOnStatus.fromJson(await _get('tryon/${Uri.encodeComponent(taskId)}'));

  /// Polls a try-on task until it finishes, emitting every status.
  /// Throws [TryOnTimeoutException] if it is still unfinished after [timeout].
  Stream<TryOnStatus> watchTryOn(
    String taskId, {
    Duration interval = const Duration(seconds: 1),
    Duration timeout = const Duration(seconds: 90),
  }) async* {
    final deadline = DateTime.now().add(timeout);
    while (true) {
      final status = await tryOnStatus(taskId);
      yield status;
      if (status.isFinal) return;
      if (!DateTime.now().isBefore(deadline)) throw TryOnTimeoutException(taskId);
      await Future<void>.delayed(interval);
    }
  }

  Future<Map<String, dynamic>> _get(String path) async =>
      _decode(await _http.get(_uri(path)));

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async =>
      _decode(await _http.post(
        _uri(path),
        headers: {'content-type': 'application/json'},
        body: jsonEncode(body),
      ));

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.body, statusCode: response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
