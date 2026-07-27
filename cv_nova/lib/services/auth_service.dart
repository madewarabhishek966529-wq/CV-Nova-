import '../models/user.dart';
import 'api_client.dart';

class AuthResult {
  const AuthResult({required this.user, required this.accessToken, required this.refreshToken});

  final User user;
  final String accessToken;
  final String refreshToken;
}

class AuthService {
  AuthService({ApiClient? apiClient}) : _api = apiClient ?? ApiClient();

  final ApiClient _api;

  Future<AuthResult> signup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final userJson = await _api.postJson(
      '/auth/signup',
      body: {'email': email, 'password': password, 'full_name': fullName},
    );
    // Signup returns the user only — log in immediately after to get tokens.
    final tokens = await _login(email, password);
    return AuthResult(
      user: User.fromJson(userJson),
      accessToken: tokens.$1,
      refreshToken: tokens.$2,
    );
  }

  Future<AuthResult> login({required String email, required String password}) async {
    final tokens = await _login(email, password);
    final user = await me(tokens.$1);
    return AuthResult(user: user, accessToken: tokens.$1, refreshToken: tokens.$2);
  }

  Future<(String, String)> _login(String email, String password) async {
    final json = await _api.postJson(
      '/auth/login',
      body: {'email': email, 'password': password},
    );
    return (json['access_token'] as String, json['refresh_token'] as String);
  }

  Future<User> me(String accessToken) async {
    final json = await _api.getJson('/users/me', token: accessToken);
    return User.fromJson(json);
  }

  Future<String> refreshAccessToken(String refreshToken) async {
    final json = await _api.postJson(
      '/auth/refresh',
      body: {'refresh_token': refreshToken},
    );
    return json['access_token'] as String;
  }
}
