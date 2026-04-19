import 'package:hockeyline/models/app_enums.dart';

class User {
  const User({
    required this.id,
    required this.email,
    required this.password,
    required this.role,
    this.fullName,
  });

  final String id;
  final String email;
  final String password;
  final UserRole role;
  final String? fullName;

  User copyWith({
    String? id,
    String? email,
    String? password,
    UserRole? role,
    String? fullName,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'password': password,
      'role': role.name,
      'fullName': fullName,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      role: UserRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => UserRole.coach,
      ),
      fullName: json['fullName'] as String?,
    );
  }
}
