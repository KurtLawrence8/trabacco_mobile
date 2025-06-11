class User {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final List<String> roles;
  final String? token;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.roles,
    this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      emailVerifiedAt: json['email_verified_at'],
      roles: List<String>.from(json['roles'] ?? []),
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'roles': roles,
      'token': token,
    };
  }
}
