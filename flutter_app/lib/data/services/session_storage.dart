import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class SessionStorage {
  Future<String?> readToken();
  Future<void> saveToken(String token);
  Future<void> clearToken();
}

class SecureSessionStorage implements SessionStorage {
  const SecureSessionStorage({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  static const _tokenKey = 'marcano_access_token';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> readToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
