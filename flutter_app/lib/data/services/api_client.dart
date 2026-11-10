import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.message, this.statusCode);

  final String message;
  final int statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;
  String? _authToken;

  set authToken(String? value) => _authToken = value;

  void Function()? onUnauthorized;

  Map<String, String> _headers({bool json = false}) => {
        if (json) 'Content-Type': 'application/json',
        if (_authToken != null) 'Authorization': 'Bearer $_authToken',
      };

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: queryParameters,
    );
    print('DEBUG: ApiClient GET request to: $uri');
    final response = await _httpClient.get(uri, headers: _headers());
    return _decode(response);
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> patchJson(String path, Map<String, dynamic> body) async {
    final response = await _httpClient.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> putJson(String path, Object body) async {
    final response = await _httpClient.put(
      Uri.parse('$baseUrl$path'),
      headers: _headers(json: true),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<dynamic> deleteJson(String path) async {
    final response =
        await _httpClient.delete(Uri.parse('$baseUrl$path'), headers: _headers());
    return _decode(response);
  }

  dynamic _decode(http.Response response) {
    final body = response.body.isEmpty
        ? null
        : jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) onUnauthorized?.call();
      final detail = body is Map<String, dynamic> ? body['detail'] : body;
      throw ApiException(
          detail?.toString() ?? 'Error de comunicacion', response.statusCode);
    }
    return body;
  }

  void close() => _httpClient.close();
}
