import '../../domain/repositories/auth_repository.dart';
import '../models/auth_session.dart';
import '../models/auth_user.dart';
import '../services/api_client.dart';

class RemoteAuthRepository implements AuthRepository {
  const RemoteAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthUser> register({
    required String fullName,
    required String cedula,
    required String password,
  }) async {
    final response = await _apiClient.postJson('/api/auth/register', {
      'full_name': fullName,
      'cedula': cedula,
      'password': password,
    });
    return AuthUser.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthSession> login({
    required String cedula,
    required String password,
  }) async {
    final response = await _apiClient.postJson('/api/auth/login', {
      'cedula': cedula,
      'password': password,
    });
    return AuthSession.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<AuthUser> me() async {
    final response = await _apiClient.getJson('/api/auth/me');
    return AuthUser.fromJson(response as Map<String, dynamic>);
  }
}
