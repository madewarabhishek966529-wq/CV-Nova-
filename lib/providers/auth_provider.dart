import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';
import '../services/token_storage.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier({AuthService? authService, TokenStorage? tokenStorage})
      : _auth = authService ?? AuthService(),
        _tokens = tokenStorage ?? TokenStorage(),
        super(const AuthState()) {
    _restoreSession();
  }

  final AuthService _auth;
  final TokenStorage _tokens;

  /// On app start: if a stored refresh token still works, restore the
  /// session silently. Otherwise fall through to unauthenticated — the
  /// router sends the user to /login.
  Future<void> _restoreSession() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null) {
      state = AuthState.signedOut;
      return;
    }

    try {
      final accessToken = await _auth.refreshAccessToken(refreshToken);
      final user = await _auth.me(accessToken);
      await _tokens.save(accessToken: accessToken, refreshToken: refreshToken);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } catch (_) {
      await _tokens.clear();
      state = AuthState.signedOut;
    }
  }

  Future<void> signup({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final result = await _auth.signup(email: email, password: password, fullName: fullName);
    await _applyResult(result);
  }

  Future<void> login({required String email, required String password}) async {
    final result = await _auth.login(email: email, password: password);
    await _applyResult(result);
  }

  Future<void> logout() async {
    await _tokens.clear();
    state = AuthState.signedOut;
  }

  Future<void> _applyResult(AuthResult result) async {
    await _tokens.save(accessToken: result.accessToken, refreshToken: result.refreshToken);
    state = AuthState(
      status: AuthStatus.authenticated,
      user: result.user,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
