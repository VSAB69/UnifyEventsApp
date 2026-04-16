class AuthResponseModel {
  final String access;
  final String refresh;
  final Map<String, dynamic> user;

  AuthResponseModel({
    required this.access,
    required this.refresh,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      access: json['access'],
      refresh: json['refresh'],
      user: json['user'],
    );
  }
}
