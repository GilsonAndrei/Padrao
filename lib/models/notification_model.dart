import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String fromUserId;
  final String fromUserName;
  final String? fromUserPhoto;
  final String toUserId;
  final String title;
  final String message;
  final String type;
  final String priority;
  final bool read;
  final bool clicked;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> data;
  final bool fromUserIsAdmin; // ✅ NOVO CAMPO
  final String? fromUserEmail; // ✅ NOVO CAMPO

  AppNotification({
    required this.id,
    required this.fromUserId,
    required this.fromUserName,
    this.fromUserPhoto,
    required this.toUserId,
    required this.title,
    required this.message,
    required this.type,
    this.priority = 'medium',
    this.read = false,
    this.clicked = false,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.data = const {},
    this.fromUserEmail, // ✅ NOVO
    this.fromUserIsAdmin = false, // ✅ NOVO
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? 'Usuário',
      fromUserPhoto: data['fromUserPhoto'],
      toUserId: data['toUserId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? 'general',
      priority: data['priority'] ?? 'medium',
      read: data['read'] ?? false,
      clicked: data['clicked'] ?? false,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      data: data['data'] ?? {},
      fromUserEmail: data['fromUserEmail'], // ✅ NOVO
      fromUserIsAdmin: data['fromUserIsAdmin'] ?? false, // ✅ NOVO
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserPhoto': fromUserPhoto,
      'toUserId': toUserId,
      'title': title,
      'message': message,
      'type': type,
      'priority': priority,
      'read': read,
      'clicked': clicked,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'data': data,
    };
  }

  AppNotification copyWith({
    String? id,
    String? fromUserId,
    String? fromUserName,
    String? fromUserPhoto,
    String? toUserId,
    String? title,
    String? message,
    String? type,
    String? priority,
    bool? read,
    bool? clicked,
    DateTime? expiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? data,
  }) {
    return AppNotification(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserPhoto: fromUserPhoto ?? this.fromUserPhoto,
      toUserId: toUserId ?? this.toUserId,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      read: read ?? this.read,
      clicked: clicked ?? this.clicked,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      data: data ?? this.data,
    );
  }
}
