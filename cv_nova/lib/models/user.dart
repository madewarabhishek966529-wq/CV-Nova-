class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.isActive,
    required this.isVerified,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;
  final bool isActive;
  final bool isVerified;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      isActive: json['is_active'] as bool,
      isVerified: json['is_verified'] as bool,
    );
  }
}
