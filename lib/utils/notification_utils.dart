import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationUtils {
  // Agrupar notificações por data
  static Map<String, List<AppNotification>> groupNotificationsByDate(
    List<AppNotification> notifications,
  ) {
    final grouped = <String, List<AppNotification>>{};

    for (final notification in notifications) {
      final group = _getDateGroup(notification.createdAt);

      if (!grouped.containsKey(group)) {
        grouped[group] = [];
      }
      grouped[group]!.add(notification);
    }

    return grouped;
  }

  static String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.isAfter(today)) {
      return 'Hoje';
    } else if (date.isAfter(yesterday)) {
      return 'Ontem';
    } else if (date.isAfter(today.subtract(const Duration(days: 7)))) {
      return 'Esta semana';
    } else {
      return DateFormat('MMMM yyyy').format(date);
    }
  }

  // Formatar data relativa
  static String formatRelativeTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  // Obter ícone baseado no tipo
  static String getNotificationIcon(String type) {
    switch (type) {
      case 'message':
        return '💬';
      case 'friend_request':
        return '👤';
      case 'like':
        return '❤️';
      case 'comment':
        return '💭';
      case 'system':
        return '🔔';
      default:
        return '📢';
    }
  }

  // Obter cor baseada no tipo
  static int getNotificationColor(String type) {
    switch (type) {
      case 'message':
        return 0xFF2196F3; // Azul
      case 'friend_request':
        return 0xFF4CAF50; // Verde
      case 'like':
        return 0xFFE91E63; // Rosa
      case 'comment':
        return 0xFFFF9800; // Laranja
      case 'system':
        return 0xFF9C27B0; // Roxo
      default:
        return 0xFF607D8B; // Cinza
    }
  }

  // Validar dados da notificação
  static Map<String, String> validateNotificationData({
    required String toUserId,
    required String title,
    required String message,
  }) {
    final errors = <String, String>{};

    if (toUserId.isEmpty) {
      errors['toUserId'] = 'ID do usuário é obrigatório';
    }

    if (title.isEmpty) {
      errors['title'] = 'Título é obrigatório';
    } else if (title.length > 100) {
      errors['title'] = 'Título muito longo (max 100 caracteres)';
    }

    if (message.isEmpty) {
      errors['message'] = 'Mensagem é obrigatória';
    } else if (message.length > 500) {
      errors['message'] = 'Mensagem muito longa (max 500 caracteres)';
    }

    return errors;
  }

  // Gerar preview da mensagem
  static String generateMessagePreview(String message, {int maxLength = 80}) {
    if (message.length <= maxLength) {
      return message;
    }
    return '${message.substring(0, maxLength)}...';
  }

  // Calcular prioridade com base no tipo
  static String calculatePriority(String type) {
    switch (type) {
      case 'friend_request':
      case 'message':
        return 'high';
      case 'like':
      case 'comment':
        return 'medium';
      default:
        return 'low';
    }
  }
}
