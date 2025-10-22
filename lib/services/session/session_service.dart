import 'package:projeto_padrao/core/constants/app_constants.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SessionService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  static const String _lastActivityKey = 'last_activity';
  static const String _deviceIdKey = 'device_id';

  static const Duration sessionDuration = AppConstants.sessionDuration;
  static DateTime? _lastActivity;

  // ✅ INICIALIZAR com dados do SharedPreferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActivityStr = prefs.getString(_lastActivityKey);

    if (lastActivityStr != null) {
      _lastActivity = DateTime.parse(lastActivityStr);
      print('🕒 [SESSION] Última atividade recuperada: $_lastActivity');
    }
  }

  // 🔐 SALVAR SESSÃO LOCAL
  static Future<void> saveSession({
    required String token,
    required Usuario usuario,
    required String deviceId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, json.encode(usuario.toMap()));
    await prefs.setString(_deviceIdKey, deviceId);
    await updateLastActivity();

    print('💾 [SESSION] Sessão salva localmente - User: ${usuario.email}');
  }

  // 🔍 RECUPERAR SESSÃO SALVA
  static Future<Map<String, dynamic>?> getSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final String? token = prefs.getString(_tokenKey);
      final String? userJson = prefs.getString(_userKey);
      final String? deviceId = prefs.getString(_deviceIdKey);

      if (token == null || userJson == null) {
        print('📭 [SESSION] Nenhuma sessão salva encontrada');
        return null;
      }

      final userMap = json.decode(userJson);
      final usuario = Usuario.fromMap(userMap);

      // Verificar se a sessão expirou
      if (isSessionExpired()) {
        print('⏰ [SESSION] Sessão expirada localmente');
        await clearSession();
        return null;
      }

      print('✅ [SESSION] Sessão recuperada: ${usuario.email}');

      return {'token': token, 'usuario': usuario, 'deviceId': deviceId};
    } catch (e) {
      print('❌ [SESSION] Erro ao recuperar sessão: $e');
      await clearSession();
      return null;
    }
  }

  // Atualizar última atividade
  static Future<void> updateLastActivity() async {
    _lastActivity = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActivityKey, _lastActivity!.toIso8601String());
  }

  // Verificar se sessão expirou
  static bool isSessionExpired() {
    return _lastActivity != null &&
        DateTime.now().difference(_lastActivity!) > sessionDuration;
  }

  // Limpar sessão
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_lastActivityKey);
    await prefs.remove(_deviceIdKey);
    _lastActivity = null;

    print('🗑️ [SESSION] Sessão local limpa');
  }
}
