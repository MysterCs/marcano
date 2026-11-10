import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:marcano_flutter/data/services/api_client.dart';

void main() {
  test('ApiClient informa cuando una sesion deja de ser valida', () async {
    var unauthorized = false;
    final client = MockClient(
      (_) async => http.Response('{"detail":"Sesion expirada"}', 401),
    );
    final api = ApiClient(baseUrl: 'http://localhost', httpClient: client)
      ..onUnauthorized = (() => unauthorized = true);

    await expectLater(api.getJson('/api/products'), throwsException);
    expect(unauthorized, isTrue);
  });

  test('ApiClient envia el token Bearer en las peticiones', () async {
    late Map<String, String> headers;
    final client = MockClient((request) async {
      headers = request.headers;
      return http.Response('[]', 200);
    });
    final api = ApiClient(baseUrl: 'http://localhost', httpClient: client)
      ..authToken = 'test-token';

    await api.getJson('/api/products');

    expect(headers['authorization'], 'Bearer test-token');
  });
}
