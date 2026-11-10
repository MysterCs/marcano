import 'auth_user.dart';

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        accessToken: json['access_token'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );

  final String accessToken;
  final AuthUser user;
}
