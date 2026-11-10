import '../../data/models/auth_session.dart';
import '../../data/models/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser> register({
    required String fullName,
    required String cedula,
    required String password,
  });

  Future<AuthSession> login({
    required String cedula,
    required String password,
  });

  Future<AuthUser> me();
}
