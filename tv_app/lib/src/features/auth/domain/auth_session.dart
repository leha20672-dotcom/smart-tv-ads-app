class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      token: (json['token'] ?? '') as String,
      user: AuthUser.fromJson(
        Map<String, dynamic>.from((json['user'] ?? <String, dynamic>{}) as Map),
      ),
    );
  }
}

class AuthUser {
  const AuthUser({required this.id, required this.email, this.name});

  final int id;
  final String email;
  final String? name;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: _asInt(json['id']),
      email: (json['email'] ?? '') as String,
      name: json['name'] as String?,
    );
  }

  static int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
