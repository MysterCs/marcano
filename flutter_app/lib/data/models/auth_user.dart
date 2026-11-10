class AuthUser {
  const AuthUser({
    required this.id,
    required this.fullName,
    required this.cedula,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        fullName: json['full_name'] as String,
        cedula: json['cedula'] as String,
      );

  final int id;
  final String fullName;
  final String cedula;
}
