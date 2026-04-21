class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final bool needsUsername;
  final bool hasPassword;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.needsUsername,
    required this.hasPassword,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'participant',
      needsUsername: json['needs_username'] ?? false,
      hasPassword: json['has_password'] ?? true,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isOrganiser => role == 'organiser';
  bool get isParticipant => role == 'participant';
}
