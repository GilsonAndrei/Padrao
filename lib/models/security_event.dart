class SecurityEvent {
  final DateTime timestamp;
  final String userId;
  final String userEmail;
  final String action;
  final String resource;
  final String? details;
  final String? ipAddress;
  final String? userAgent;
  final String? deviceId;
  final SecurityRiskLevel riskLevel;
  final SecuritySeverity severity;

  SecurityEvent({
    required this.timestamp,
    required this.userId,
    required this.userEmail,
    required this.action,
    required this.resource,
    this.details,
    this.ipAddress,
    this.userAgent,
    this.deviceId,
    required this.riskLevel,
    required this.severity,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'userEmail': userEmail,
      'action': action,
      'resource': resource,
      'details': details,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'deviceId': deviceId,
      'riskLevel': riskLevel.toString(),
      'severity': severity.toString(),
    };
  }

  factory SecurityEvent.fromMap(Map<String, dynamic> map) {
    return SecurityEvent(
      timestamp: DateTime.parse(map['timestamp']),
      userId: map['userId'],
      userEmail: map['userEmail'],
      action: map['action'],
      resource: map['resource'],
      details: map['details'],
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
      deviceId: map['deviceId'],
      riskLevel: SecurityRiskLevel.values.firstWhere(
        (e) => e.toString() == map['riskLevel'],
      ),
      severity: SecuritySeverity.values.firstWhere(
        (e) => e.toString() == map['severity'],
      ),
    );
  }
}

enum SecurityRiskLevel { low, medium, high, critical }

enum SecuritySeverity { low, medium, high, critical }

class SecurityReport {
  final String userId;
  final String period;
  final int totalEvents;
  final int highRiskEvents;
  final List<String> suspiciousPatterns;
  final List<String> recommendations;

  SecurityReport({
    required this.userId,
    required this.period,
    required this.totalEvents,
    required this.highRiskEvents,
    required this.suspiciousPatterns,
    required this.recommendations,
  });
}
