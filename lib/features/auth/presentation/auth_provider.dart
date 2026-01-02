import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

class AuthNotifier extends AsyncNotifier<UserModel?> {
  static const _userKey = 'user_username';
  static const _passKey = 'user_password';

  @override
  FutureOr<UserModel?> build() async {
    return _restoreSession();
  }

  Future<UserModel?> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_userKey);
    final password = prefs.getString(_passKey);

    if (username != null && password != null) {
      try {
        final user = await ref
            .read(authRepositoryProvider)
            .loginUser(username: username, password: password);
        return user;
      } catch (_) {
        await logout();
      }
    }
    return null;
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref
          .read(authRepositoryProvider)
          .loginUser(username: username, password: password);

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, username);
        await prefs.setString(_passKey, password);
        return user;
      } else {
        throw Exception('Hatalı Kullanıcı Adı veya Şifre');
      }
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
    await prefs.remove(_passKey);
    state = const AsyncValue.data(null);
  }

  /// Silently refreshes user data without triggering loading state
  Future<void> refreshUser() async {
    final currentUser = state.asData?.value;
    if (currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_userKey);
    final password = prefs.getString(_passKey);

    if (username != null && password != null) {
      // Don't set state to loading
      state = await AsyncValue.guard(() async {
        return await ref
            .read(authRepositoryProvider)
            .loginUser(username: username, password: password);
      });
    }
  }
}

final authNotifierProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(() {
  return AuthNotifier();
});
