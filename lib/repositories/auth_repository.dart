import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/mock_api_service.dart';

abstract class IAuthRepository {
  Future<UserModel> login(String email, String password, {bool rememberMe = false});
  Future<void> logout();
  Future<UserModel?> getSavedSession();
  Future<String?> getSavedEmail();
  Future<bool> forgotPassword(String email);
  UserModel? getCurrentUser();
  bool get isSimulatedOffline;
  void toggleSimulateOffline(bool offline);
}

class AuthRepository implements IAuthRepository {
  final IApiService _apiService;
  UserModel? _currentUser;
  static const String _sessionKey = 'auth_saved_user_session';
  static const String _rememberEmailKey = 'auth_saved_email';

  AuthRepository(this._apiService);

  @override
  bool get isSimulatedOffline => _apiService.isOffline;

  @override
  void toggleSimulateOffline(bool offline) {
    _apiService.setOfflineMode(offline);
  }

  @override
  Future<UserModel> login(String email, String password, {bool rememberMe = false}) async {
    final user = await _apiService.login(email, password);
    _currentUser = user;

    final prefs = await SharedPreferences.getInstance();
    if (rememberMe) {
      await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
      await prefs.setString(_rememberEmailKey, email);
    } else {
      await prefs.remove(_sessionKey);
      await prefs.setString(_rememberEmailKey, email); // Keep email for convenience
    }

    return user;
  }

  @override
  Future<UserModel?> getSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_sessionKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        final user = UserModel.fromJson(map);
        _currentUser = user;
        return user;
      }
    } catch (_) {
      // In case of corrupt session data, clear it
    }
    return null;
  }

  @override
  Future<String?> getSavedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_rememberEmailKey);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> forgotPassword(String email) async {
    // Simulated government OTP / Password reset link issuance
    await Future.delayed(const Duration(milliseconds: 600));
    return email.contains('@');
  }

  @override
  Future<void> logout() async {
    _currentUser = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } catch (_) {}
  }

  @override
  UserModel? getCurrentUser() => _currentUser;
}
