// services/session_expiry_service.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class SessionExpiryService {
  static final CollectionReference _sessions = FirebaseFirestore.instance
      .collection('active_sessions');

  static const Duration SESSION_DURATION = Duration(hours: 4);
  static Timer? _cleanupTimer;

  // Iniciar serviço de limpeza automática
  static void startAutoCleanup() {
    // Executar limpeza a cada hora
    _cleanupTimer = Timer.periodic(Duration(hours: 1), (timer) {
      _cleanupAllExpiredSessions();
    });

    print('⏰ [EXPIRY] Serviço de expiração de sessão iniciado');
  }

  // Parar serviço
  static void stopAutoCleanup() {
    _cleanupTimer?.cancel();
    print('⏹️ [EXPIRY] Serviço de expiração de sessão parado');
  }

  // Limpar todas as sessões expiradas de todos os usuários
  static Future<void> _cleanupAllExpiredSessions() async {
    try {
      print('🧹 [EXPIRY] Iniciando limpeza global de sessões expiradas...');

      final cutoffTime = DateTime.now().subtract(SESSION_DURATION);
      int totalExpired = 0;

      // Buscar todos os usuários com sessões ativas
      final usersSnapshot = await _sessions.get();

      for (final userDoc in usersSnapshot.docs) {
        final sessionsSnapshot = await userDoc.reference
            .collection('devices')
            .where('lastActivity', isLessThan: cutoffTime)
            .where('isActive', isEqualTo: true)
            .get();

        for (final sessionDoc in sessionsSnapshot.docs) {
          await sessionDoc.reference.update({
            'isActive': false,
            'expiredAt': DateTime.now(),
            'expirationReason': 'auto_timeout',
          });
          totalExpired++;
        }
      }

      if (totalExpired > 0) {
        print(
          '✅ [EXPIRY] $totalExpired sessões expiradas foram limpas globalmente',
        );
      } else {
        print('ℹ️ [EXPIRY] Nenhuma sessão expirada encontrada');
      }
    } catch (e) {
      print('❌ [EXPIRY] Erro na limpeza global: $e');
    }
  }

  // Forçar expiração para testes
  static Future<void> forceSessionExpiration(
    String userId,
    String deviceId,
  ) async {
    try {
      await _sessions.doc(userId).collection('devices').doc(deviceId).update({
        'lastActivity': DateTime.now().subtract(
          Duration(days: 1),
        ), // Forçar expiração
      });

      print('🧪 [EXPIRY] Expiração forçada para testes');
    } catch (e) {
      print('❌ [EXPIRY] Erro ao forçar expiração: $e');
    }
  }
}
