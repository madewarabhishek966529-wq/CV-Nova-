import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../utils/constants.dart';
import 'api_exceptions.dart';

/// Thin wrapper over [http.Client] — every backend call in the app should
/// go through here rather than calling `http` directly, so JSON handling
/// and error translation stay in one place.
///
/// No auth headers: CVNova runs single-user/local, and the backend treats
/// every request as the same implicit local user — there's nothing to
/// attach here.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _baseUrl = AppConstants.apiBaseUrl;

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  static const _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<Map<String, dynamic>> getJson(String path) async {
    final response = await _send(() => _client.get(_uri(path), headers: _headers));
    return _decodeObject(response);
  }

  Future<List<dynamic>> getJsonList(String path) async {
    final response = await _send(() => _client.get(_uri(path), headers: _headers));
    return _decodeList(response);
  }

  Future<Map<String, dynamic>> postJson(String path, {Map<String, dynamic>? body}) async {
    final response = await _send(
      () => _client.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})),
    );
    return _decodeObject(response);
  }

  Future<Map<String, dynamic>> putJson(String path, {required Map<String, dynamic> body}) async {
    final response = await _send(
      () => _client.put(_uri(path), headers: _headers, body: jsonEncode(body)),
    );
    return _decodeObject(response);
  }

  Future<void> delete(String path) async {
    await _send(() => _client.delete(_uri(path), headers: _headers));
  }

  /// Multipart upload — used for the ATS PDF analyzer. Kept separate from
  /// [postJson] since the request body shape (file + form fields) is
  /// fundamentally different from a JSON body.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required String fileFieldName,
    required List<int> fileBytes,
    required String filename,
    Map<String, String>? fields,
  }) async {
    final response = await _send(() async {
      final request = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll({'Accept': 'application/json'})
        ..files.add(http.MultipartFile.fromBytes(fileFieldName, fileBytes, filename: filename));
      if (fields != null) request.fields.addAll(fields);
      final streamed = await _client.send(request);
      return http.Response.fromStream(streamed);
    });
    return _decodeObject(response);
  }

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(const Duration(seconds: 15));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response;
      }
      throw ApiException(
        statusCode: response.statusCode,
        message: _extractDetail(response),
      );
    } on ApiException {
      rethrow;
    } on SocketException {
      throw const NetworkException();
    } on HttpException {
      throw const NetworkException();
    } catch (_) {
      throw const NetworkException();
    }
  }

  String _extractDetail(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        final detail = decoded['detail'];
        // FastAPI validation errors return a list of {loc, msg, type}.
        if (detail is List && detail.isNotEmpty && detail.first is Map) {
          return (detail.first as Map)['msg']?.toString() ?? 'Validation error';
        }
        return detail.toString();
      }
    } catch (_) {
      // fall through to generic message
    }
    return 'Request failed (${response.statusCode})';
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  List<dynamic> _decodeList(http.Response response) {
    if (response.body.isEmpty) return [];
    return jsonDecode(response.body) as List<dynamic>;
  }
}
