// services/audit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/models/usuario.dart';

class AuditService {
  static void logLogin(Usuario usuario, bool success, String? error) {
    final event = {
      'timestamp': DateTime.now().toIso8601String(),
      'userId': usuario.id,
      'email': usuario.email,
      'event': 'login',
      'success': success,
      'error': error,
      'ip': 'client_ip', // Em apps web você pode capturar o IP
      'userAgent': 'flutter_app',
    };

    print('📊 [AUDIT] Login: $event');

    // Salvar no Firestore para auditoria
    FirebaseFirestore.instance.collection('audit_logs').add(event);
  }

  static void logSecurityEvent(String event, Usuario usuario, String details) {
    final securityEvent = {
      'timestamp': DateTime.now().toIso8601String(),
      'userId': usuario.id,
      'event': event,
      'details': details,
      'severity': 'medium',
    };

    FirebaseFirestore.instance.collection('security_events').add(securityEvent);
  }
}
