// services/session_tracker_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:projeto_padrao/models/usuario.dart';

class SessionTrackerService {
  // 👇 CONFIGURAÇÃO DE EXPIRAÇÃO
  static const Duration SESSION_DURATION = Duration(hours: 4); // 4 horas
  static const Duration CLEANUP_INTERVAL = Duration(
    hours: 1,
  ); // Verificar a cada 1h
  static final CollectionReference _sessions = FirebaseFirestore.instance
      .collection('active_sessions');

  // Registrar nova sessão COM DEVICE ID REAL
  static Future<void> registerNewSession(
    Usuario usuario,
    String deviceId,
  ) async {
    print('💾 [SESSION] Registrando nova sessão:');
    print('   👤 Usuário: ${usuario.email}');
    print('   📱 Device: $deviceId');

    await _sessions.doc(usuario.id).collection('devices').doc(deviceId).set({
      'userId': usuario.id,
      'userEmail': usuario.email,
      'deviceId': deviceId,
      'deviceName': _getDeviceName(),
      'loginTime': DateTime.now(),
      'lastActivity': DateTime.now(),
      'ipAddress': 'web_browser', // Ou 'mobile_app'
      'isActive': true,
      'userAgent': 'flutter_web', // Você pode capturar o user agent real
    });

    print('✅ [SESSION] Sessão registrada com sucesso');
  }

  static String _getDeviceName() {
    // Em produção, você pode detectar se é mobile, tablet, desktop, etc.
    return 'Navegador Web - ${DateTime.now().toString()}';
  }

  // Verificar e limpar sessões expiradas
  static Future<void> cleanupExpiredSessions(String userId) async {
    try {
      print('🧹 [SESSION] Limpando sessões expiradas para: $userId');

      final cutoffTime = DateTime.now().subtract(SESSION_DURATION);

      final snapshot = await _sessions
          .doc(userId)
          .collection('devices')
          .where('lastActivity', isLessThan: cutoffTime)
          .where('isActive', isEqualTo: true)
          .get();

      int expiredCount = 0;

      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'isActive': false,
          'expiredAt': DateTime.now(),
          'expirationReason': 'session_timeout',
        });
        expiredCount++;
      }

      if (expiredCount > 0) {
        print('✅ [SESSION] $expiredCount sessões expiradas foram limpas');
      }
    } catch (e) {
      print('❌ [SESSION] Erro ao limpar sessões expiradas: $e');
    }
  }

  // Atualizar última atividade (chamar em toda interação do usuário)
  static Future<void> updateLastActivity(String userId, String deviceId) async {
    try {
      await _sessions.doc(userId).collection('devices').doc(deviceId).update({
        'lastActivity': DateTime.now(),
      });
    } catch (e) {
      print('❌ [SESSION] Erro ao atualizar última atividade: $e');
    }
  }

  // Verificar se a sessão atual está expirada
  static Future<bool> isSessionExpired(String userId, String deviceId) async {
    try {
      final doc = await _sessions
          .doc(userId)
          .collection('devices')
          .doc(deviceId)
          .get();

      if (!doc.exists) return true;

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || data['isActive'] != true) return true;

      final lastActivity = data['lastActivity'];
      if (lastActivity is Timestamp) {
        final lastActivityTime = lastActivity.toDate();
        final now = DateTime.now();

        return now.difference(lastActivityTime) > SESSION_DURATION;
      }

      return true;
    } catch (e) {
      print('❌ [SESSION] Erro ao verificar expiração: $e');
      return true;
    }
  }

  // Obter sessões ativas (excluindo a atual) - CORRIGIDO
  static Future<List<Map<String, dynamic>>> getOtherActiveSessions(
    String userId,
    String currentDeviceId,
  ) async {
    try {
      print('🔍 [SESSION] Buscando outras sessões para: $userId');
      print('   📱 Excluindo device: $currentDeviceId');

      final snapshot = await _sessions
          .doc(userId)
          .collection('devices')
          .where('isActive', isEqualTo: true)
          .get();

      final allSessions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      // Filtrar para excluir a sessão atual
      final otherSessions = allSessions
          .where((session) => session['deviceId'] != currentDeviceId)
          .toList();

      print(
        '📊 [SESSION] Encontradas ${otherSessions.length} outras sessões ativas',
      );

      return otherSessions;
    } catch (e) {
      print('❌ [SESSION] Erro ao buscar outras sessões: $e');
      return [];
    }
  }

  // Verificar se existe sessão em outro dispositivo - CORRIGIDO
  static Future<bool> hasOtherActiveSessions(
    String userId,
    String currentDeviceId,
  ) async {
    final otherSessions = await getOtherActiveSessions(userId, currentDeviceId);
    final hasSessions = otherSessions.isNotEmpty;

    print('🔍 [SESSION] Verificação de outras sessões: $hasSessions');
    return hasSessions;
  }

  // Terminar outras sessões
  static Future<void> terminateOtherSessions(
    String userId,
    String currentDeviceId,
  ) async {
    final otherSessions = await getOtherActiveSessions(userId, currentDeviceId);

    for (final session in otherSessions) {
      await _sessions
          .doc(userId)
          .collection('devices')
          .doc(session['id'])
          .update({
            'isActive': false,
            'terminatedAt': DateTime.now(),
            'terminatedBy': currentDeviceId,
          });
    }
  }

  // Terminar sessão específica
  static Future<void> terminateSession(String userId, String deviceId) async {
    await _sessions.doc(userId).collection('devices').doc(deviceId).update({
      'isActive': false,
      'terminatedAt': DateTime.now(),
    });
  }

  // Atualizar sessão atual como inativa
  static Future<void> terminateCurrentSession(
    String userId,
    String deviceId,
  ) async {
    await _sessions.doc(userId).collection('devices').doc(deviceId).update({
      'isActive': false,
      'logoutTime': DateTime.now(),
    });
  }

  // Limpar sessões antigas (manutenção)
  static Future<void> cleanupOldSessions(String userId) async {
    final monthAgo = DateTime.now().subtract(Duration(days: 30));

    final snapshot = await _sessions
        .doc(userId)
        .collection('devices')
        .where('loginTime', isLessThan: monthAgo)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
