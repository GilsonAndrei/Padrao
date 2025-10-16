// services/security_monitor_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:projeto_padrao/models/security_event.dart';
import '../../models/usuario.dart';

class SecurityMonitorService {
  static final SecurityMonitorService _instance =
      SecurityMonitorService._internal();
  factory SecurityMonitorService() => _instance;
  SecurityMonitorService._internal();

  // Configurações de monitoramento
  static const _maxLoginAttempts = 5;
  static const _loginTimeWindow = Duration(minutes: 15);
  static const _suspiciousActivityThreshold = 3;

  // Armazenamento temporário em memória
  final Map<String, List<DateTime>> _loginAttempts = {};
  final Map<String, List<SecurityEvent>> _userActivities = {};
  final Map<String, int> _suspiciousActivityCount = {};

  // Tipos de atividades de alto risco
  static const _highRiskActivities = [
    'password_change',
    'email_change',
    'permission_change',
    'user_deletion',
    'data_export',
    'admin_access',
  ];

  // Padrões de comportamento suspeito
  static const _suspiciousPatterns = [
    'multiple_failed_logins',
    'login_from_new_device',
    'unusual_time_access',
    'bulk_data_access',
    'permission_escalation',
  ];

  // Monitora qualquer atividade do usuário
  static void monitorUserActivity({
    required Usuario usuario,
    required String action,
    required String resource,
    String? details,
    String? ipAddress,
    String? userAgent,
    String? deviceId,
    SecuritySeverity severity = SecuritySeverity.low,
  }) {
    final event = SecurityEvent(
      timestamp: DateTime.now(),
      userId: usuario.id,
      userEmail: usuario.email,
      action: action,
      resource: resource,
      details: details,
      ipAddress: ipAddress,
      userAgent: userAgent,
      deviceId: deviceId,
      riskLevel: _calculateRiskLevel(action, resource, usuario),
      severity: _calculateSeverity(action, resource),
    );

    _instance._processEvent(event);
  }

  // Processa o evento de segurança
  void _processEvent(SecurityEvent event) {
    // Adiciona à lista de atividades do usuário
    _userActivities.putIfAbsent(event.userId, () => []).add(event);

    // Limita o histórico para evitar memory leak
    if (_userActivities[event.userId]!.length > 1000) {
      _userActivities[event.userId]!.removeAt(0);
    }

    // Analisa padrões suspeitos
    final suspiciousPatterns = _analyzeForSuspiciousPatterns(event);

    // Se detectou padrões suspeitos, toma ação
    if (suspiciousPatterns.isNotEmpty) {
      _handleSuspiciousActivity(event, suspiciousPatterns);
    }

    // Se é evento de alto risco, log imediatamente
    if (event.severity == SecuritySeverity.high ||
        event.severity == SecuritySeverity.critical) {
      _logSecurityEvent(event, suspiciousPatterns);
    }

    // Envia para dashboard em tempo real
    _sendToRealTimeDashboard(event);
  }

  // Analisa padrões suspeitos em tempo real
  List<String> _analyzeForSuspiciousPatterns(SecurityEvent currentEvent) {
    final patterns = <String>[];
    final userActivities = _userActivities[currentEvent.userId] ?? [];

    // 1. Múltiplas tentativas de login falhadas
    if (currentEvent.action == 'login_failed') {
      final recentFailures = userActivities
          .where(
            (e) =>
                e.action == 'login_failed' &&
                e.timestamp.isAfter(DateTime.now().subtract(_loginTimeWindow)),
          )
          .length;

      if (recentFailures >= _maxLoginAttempts) {
        patterns.add('multiple_failed_logins');
      }
    }

    // 2. Acesso em horário incomum
    if (_isUnusualAccessTime(currentEvent)) {
      patterns.add('unusual_time_access');
    }

    // 3. Múltiplas alterações sensíveis em curto período
    if (_highRiskActivities.contains(currentEvent.action)) {
      final recentHighRisk = userActivities
          .where(
            (e) =>
                _highRiskActivities.contains(e.action) &&
                e.timestamp.isAfter(
                  DateTime.now().subtract(Duration(hours: 1)),
                ),
          )
          .length;

      if (recentHighRisk >= 2) {
        patterns.add('rapid_sensitive_changes');
      }
    }

    // 4. Acesso a recursos incomuns para o perfil
    if (_isUnusualResourceAccess(currentEvent)) {
      patterns.add('unusual_resource_access');
    }

    return patterns;
  }

  // Verifica se é horário incomum de acesso
  bool _isUnusualAccessTime(SecurityEvent event) {
    final hour = event.timestamp.hour;
    // Horário comercial: 8h-18h, fora disso é incomum
    return hour < 8 || hour > 18;
  }

  // Verifica acesso a recursos incomuns
  bool _isUnusualResourceAccess(SecurityEvent event) {
    final userResources = _userActivities[event.userId]!
        .where((e) => e.resource != null)
        .map((e) => e.resource!)
        .toSet();

    // Se é um recurso nunca acessado antes
    return !userResources.contains(event.resource);
  }

  // Calcula nível de risco
  static SecurityRiskLevel _calculateRiskLevel(
    String action,
    String resource,
    Usuario usuario,
  ) {
    // Atividades de alto risco independente do usuário
    if ([
      'user_deletion',
      'permission_escalation',
      'data_export',
    ].contains(action)) {
      return SecurityRiskLevel.high;
    }

    // Se usuário não é admin tentando acessar recursos admin
    if (resource.contains('admin') &&
        !usuario.perfil.permissoes.contains('ADMIN')) {
      return SecurityRiskLevel.critical;
    }

    // Alterações sensíveis
    if (['password_change', 'email_change'].contains(action)) {
      return SecurityRiskLevel.medium;
    }

    return SecurityRiskLevel.low;
  }

  // Calcula severidade
  static SecuritySeverity _calculateSeverity(String action, String resource) {
    const criticalActions = ['user_deletion', 'system_config_change'];
    const highRiskActions = ['permission_change', 'data_export', 'admin_login'];

    if (criticalActions.contains(action)) return SecuritySeverity.critical;
    if (highRiskActions.contains(action)) return SecuritySeverity.high;
    if (action.contains('change')) return SecuritySeverity.medium;

    return SecuritySeverity.low;
  }

  // Manipula atividade suspeita
  void _handleSuspiciousActivity(SecurityEvent event, List<String> patterns) {
    print('🚨 ATIVIDADE SUSPEITA DETECTADA:');
    print('   Usuário: ${event.userEmail}');
    print('   Ação: ${event.action}');
    print('   Padrões: ${patterns.join(', ')}');
    print('   Risco: ${event.riskLevel}');
    print('   Severidade: ${event.severity}');

    // Incrementa contador de atividades suspeitas
    _suspiciousActivityCount[event.userId] =
        (_suspiciousActivityCount[event.userId] ?? 0) + 1;

    // Ações baseadas na severidade
    switch (event.severity) {
      case SecuritySeverity.low:
        _logSecurityEvent(event, patterns);
        break;

      case SecuritySeverity.medium:
        _logSecurityEvent(event, patterns);
        _notifyUser(event, 'Atividade incomum detectada');
        break;

      case SecuritySeverity.high:
        _logSecurityEvent(event, patterns);
        _notifyUser(
          event,
          'Atividade suspeita detectada - Verifique sua conta',
        );
        _notifyAdmins(event, 'Atividade suspeita de alto risco');
        break;

      case SecuritySeverity.critical:
        _logSecurityEvent(event, patterns);
        _notifyAdmins(
          event,
          'ATIVIDADE CRÍTICA DETECTADA - AÇÃO IMEDIATA REQUERIDA',
        );
        _forceAdditionalVerification(event.userId);
        _temporarilyRestrictAccount(event.userId);
        break;
    }

    // Se excedeu o threshold, força verificação
    if (_suspiciousActivityCount[event.userId]! >=
        _suspiciousActivityThreshold) {
      _forceAccountVerification(event.userId);
    }
  }

  // Força verificação adicional
  void _forceAdditionalVerification(String userId) {
    print('🔐 Forçando verificação adicional para usuário: $userId');
    // Implementar: 2FA, captcha, email de verificação, etc.
  }

  // Restrição temporária da conta
  void _temporarilyRestrictAccount(String userId) {
    print('⛔ Restringindo temporariamente conta: $userId');
    // Implementar: Bloqueio temporário, limitação de funcionalidades
  }

  // Força verificação completa da conta
  void _forceAccountVerification(String userId) {
    print('🛡️ Forçando verificação completa da conta: $userId');
    // Implementar: Reautenticação, contato com suporte, etc.
  }

  // Notifica o usuário
  void _notifyUser(SecurityEvent event, String message) {
    // Implementar: Push notification, email, SMS
    print('📧 Notificando usuário: $message');
  }

  // Notifica administradores
  void _notifyAdmins(SecurityEvent event, String message) {
    // Implementar: Slack, Email, Dashboard de admin
    print('👨‍💼 Notificando admins: $message');
  }

  // Log de evento de segurança
  void _logSecurityEvent(SecurityEvent event, List<String> patterns) async {
    try {
      final logData = {
        'timestamp': event.timestamp.toIso8601String(),
        'userId': event.userId,
        'userEmail': event.userEmail,
        'action': event.action,
        'resource': event.resource,
        'details': event.details,
        'ipAddress': event.ipAddress,
        'userAgent': event.userAgent,
        'deviceId': event.deviceId,
        'riskLevel': event.riskLevel.toString(),
        'severity': event.severity.toString(),
        'suspiciousPatterns': patterns,
        'investigationStatus': 'pending',
      };

      await FirebaseFirestore.instance
          .collection('security_monitoring')
          .add(logData);

      print('📊 Evento de segurança registrado: ${event.action}');
    } catch (e) {
      print('❌ Erro ao registrar evento de segurança: $e');
    }
  }

  // Dashboard em tempo real
  void _sendToRealTimeDashboard(SecurityEvent event) {
    // Implementar: WebSockets, Firebase Realtime Database, etc.
    // Para dashboard de monitoramento em tempo real
  }

  // Relatórios e analytics
  static Future<SecurityReport> generateSecurityReport({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final events = await _getUserEventsInPeriod(userId, startDate, endDate);

    return SecurityReport(
      userId: userId,
      period: '$startDate to $endDate',
      totalEvents: events.length,
      highRiskEvents: events
          .where((e) => e.severity.index >= SecuritySeverity.high.index)
          .length,
      suspiciousPatterns: _analyzeReportPatterns(events),
      recommendations: _generateRecommendations(events),
    );
  }

  static Future<List<SecurityEvent>> _getUserEventsInPeriod(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    // Busca eventos do Firestore
    final snapshot = await FirebaseFirestore.instance
        .collection('security_monitoring')
        .where('userId', isEqualTo: userId)
        .where('timestamp', isGreaterThan: start.toIso8601String())
        .where('timestamp', isLessThan: end.toIso8601String())
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return SecurityEvent.fromMap(data);
    }).toList();
  }

  static List<String> _analyzeReportPatterns(List<SecurityEvent> events) {
    final patterns = <String>{};

    for (final event in events) {
      if (event.riskLevel == SecurityRiskLevel.high ||
          event.riskLevel == SecurityRiskLevel.critical) {
        patterns.add('high_risk_activity_detected');
      }
    }

    return patterns.toList();
  }

  static List<String> _generateRecommendations(List<SecurityEvent> events) {
    final recommendations = <String>[];

    final highRiskCount = events
        .where((e) => e.severity.index >= SecuritySeverity.high.index)
        .length;

    if (highRiskCount > 5) {
      recommendations.add('Considerar verificação de identidade do usuário');
    }

    if (events.any((e) => e.action.contains('failed_login'))) {
      recommendations.add('Implementar política de senhas mais forte');
    }

    return recommendations;
  }
}

// Modelos de dados para o sistema de monitoramento
