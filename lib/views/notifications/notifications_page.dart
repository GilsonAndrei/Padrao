import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projeto_padrao/models/notification_model.dart';
import 'package:projeto_padrao/services/notification/notification_service.dart';
import 'package:projeto_padrao/utils/notification_utils.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String _filterType = 'all';
  final List<String> _filterTypes = [
    'all',
    'unread',
    'message',
    'friend_request',
    'system',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      print('🔍 Carregando notificações...');

      final snapshot = await _notificationService.getNotificationsPaginated(
        limit: 50,
      );

      print('📊 Notificações encontradas: ${snapshot.docs.length}');

      _notifications.clear();
      _notifications.addAll(
        snapshot.docs.map((doc) {
          print('📄 Notificação: ${doc.id} - ${doc.data()}');
          return AppNotification.fromFirestore(doc);
        }).toList(),
      );

      print('✅ Notificações carregadas: ${_notifications.length}');
    } catch (e) {
      print('❌ Erro ao carregar notificações: $e');
    }

    setState(() => _isLoading = false);
  }

  List<AppNotification> get _filteredNotifications {
    if (_filterType == 'all') return _notifications;
    if (_filterType == 'unread') {
      return _notifications.where((n) => !n.read).toList();
    }
    return _notifications.where((n) => n.type == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notificações'),
        actions: [_buildFilterMenu(), _buildMarkAllButton()],
      ),
      body: _isLoading
          ? _buildLoading()
          : _filteredNotifications.isEmpty
          ? _buildEmptyState()
          : _buildNotificationsList(),
    );
  }

  Widget _buildFilterMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        setState(() => _filterType = value);
      },
      itemBuilder: (context) => _filterTypes.map((type) {
        return PopupMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(_getFilterIcon(type), color: _getFilterColor(type)),
              SizedBox(width: 8),
              Text(_getFilterText(type)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMarkAllButton() {
    return StreamBuilder<int>(
      stream: _notificationService.getUnreadCount(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;
        if (unreadCount == 0) return SizedBox();

        return IconButton(
          icon: Icon(Icons.mark_email_read),
          tooltip: 'Marcar todas como lidas',
          onPressed: _markAllAsRead,
        );
      },
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando notificações...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            _filterType == 'all'
                ? 'Nenhuma notificação'
                : 'Nenhuma notificação ${_getFilterText(_filterType).toLowerCase()}',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          if (_filterType != 'all')
            TextButton(
              onPressed: () => setState(() => _filterType = 'all'),
              child: Text('Ver todas as notificações'),
            ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    final groupedNotifications = NotificationUtils.groupNotificationsByDate(
      _filteredNotifications,
    );
    final groups = groupedNotifications.entries.toList();

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, groupIndex) {
          final group = groups[groupIndex];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  group.key,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
              ...group.value
                  .map((notification) => _buildNotificationItem(notification))
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(AppNotification notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await _showDeleteDialog(notification);
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        color: notification.read ? Colors.white : Colors.blue[50],
        elevation: 1,
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(
                NotificationUtils.getNotificationColor(notification.type),
              ).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                NotificationUtils.getNotificationIcon(notification.type),
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.read
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
              ),
              if (!notification.read)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              SizedBox(height: 4),
              Text(
                NotificationUtils.formatRelativeTime(
                  Timestamp.fromDate(notification.createdAt),
                ),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) =>
                _handleNotificationAction(value, notification),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.mark_email_read, size: 20),
                    SizedBox(width: 8),
                    Text(
                      notification.read
                          ? 'Marcar como não lida'
                          : 'Marcar como lida',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'view_details',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20),
                    SizedBox(width: 8),
                    Text('Ver detalhes'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Deletar', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          onTap: () => _handleNotificationTap(notification),
        ),
      ),
    );
  }

  Future<bool> _showDeleteDialog(AppNotification notification) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deletar Notificação?'),
        content: Text('Tem certeza que deseja deletar esta notificação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _notificationService.deleteNotification(notification.id);
      setState(() {
        _notifications.removeWhere((n) => n.id == notification.id);
      });
    }

    return result ?? false;
  }

  void _handleNotificationAction(String action, AppNotification notification) {
    switch (action) {
      case 'mark_read':
        _toggleReadStatus(notification);
        break;
      case 'view_details':
        _showNotificationDetails(notification);
        break;
      case 'delete':
        _deleteNotification(notification);
        break;
    }
  }

  void _handleNotificationTap(AppNotification notification) {
    if (!notification.read) {
      _markAsRead(notification);
    }
    _showNotificationDetails(notification);
  }

  void _toggleReadStatus(AppNotification notification) {
    if (notification.read) {
      // Marcar como não lida - precisaríamos criar um método para isso
      // Por enquanto, apenas marcar como lida
      _markAsRead(notification);
    } else {
      _markAsRead(notification);
    }
  }

  void _markAsRead(AppNotification notification) async {
    await _notificationService.markAsRead(notification.id);
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(read: true);
      }
    });
  }

  void _markAllAsRead() async {
    await _notificationService.markAllAsRead();
    await _loadNotifications(); // Recarregar a lista
  }

  void _deleteNotification(AppNotification notification) async {
    await _notificationService.deleteNotification(notification.id);
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Notificação deletada'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showNotificationDetails(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalhes da Notificação'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Título', notification.title),
              _buildDetailRow('Mensagem', notification.message),
              _buildDetailRow('Tipo', _getFilterText(notification.type)),
              _buildDetailRow('Prioridade', notification.priority),
              _buildDetailRow(
                'Status',
                notification.read ? 'Lida' : 'Não lida',
              ),
              _buildDetailRow('Remetente', notification.fromUserName),
              _buildDetailRow(
                'Data',
                DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
              ),
              if (notification.data.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  'Dados Adicionais:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...notification.data.entries
                    .map(
                      (entry) =>
                          _buildDetailRow(entry.key, entry.value.toString()),
                    )
                    .toList(),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  // Helpers para filtros
  IconData _getFilterIcon(String type) {
    switch (type) {
      case 'all':
        return Icons.all_inbox;
      case 'unread':
        return Icons.mark_email_unread;
      case 'message':
        return Icons.message;
      case 'friend_request':
        return Icons.person_add;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  Color _getFilterColor(String type) {
    switch (type) {
      case 'all':
        return Colors.blue;
      case 'unread':
        return Colors.orange;
      case 'message':
        return Colors.green;
      case 'friend_request':
        return Colors.purple;
      case 'system':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getFilterText(String type) {
    switch (type) {
      case 'all':
        return 'Todas';
      case 'unread':
        return 'Não lidas';
      case 'message':
        return 'Mensagens';
      case 'friend_request':
        return 'Solicitações';
      case 'system':
        return 'Sistema';
      default:
        return type;
    }
  }
}
