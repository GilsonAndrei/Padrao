// services/session_service.dart
import 'package:projeto_padrao/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Tempo de expiração da sessão (4 horas)
  static const Duration sessionDuration = AppConstants.sessionDuration;
  static DateTime? _lastActivity;

  static void updateLastActivity() {
    _lastActivity = DateTime.now();
  }

  static bool isSessionExpired() {
    return _lastActivity != null &&
        DateTime.now().difference(_lastActivity!) > sessionDuration;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _lastActivity = null;
  }
}
