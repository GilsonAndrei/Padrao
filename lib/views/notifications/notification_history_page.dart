import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:projeto_padrao/models/notification_model.dart';
import 'package:projeto_padrao/services/notification/notification_service.dart';
import 'package:projeto_padrao/utils/notification_utils.dart';

class NotificationHistoryPage extends StatefulWidget {
  @override
  _NotificationHistoryPageState createState() =>
      _NotificationHistoryPageState();
}

class _NotificationHistoryPageState extends State<NotificationHistoryPage> {
  final NotificationService _notificationService = NotificationService();
  final List<AppNotification> _notifications = [];
  final List<DocumentSnapshot> _documentSnapshots = [];
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadInitialNotifications();
  }

  Future<void> _loadInitialNotifications() async {
    setState(() => _isLoading = true);

    try {
      final snapshot = await _notificationService.getNotificationsPaginated(
        limit: _pageSize,
      );

      _processSnapshot(snapshot);
    } catch (e) {
      print('Erro ao carregar notificações iniciais: $e');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loadMoreNotifications() async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _notificationService.getNotificationsPaginated(
        limit: _pageSize,
        lastDocument: _lastDocument,
      );

      _processSnapshot(snapshot);
    } catch (e) {
      print('Erro ao carregar mais notificações: $e');
    }

    setState(() => _isLoading = false);
  }

  void _processSnapshot(QuerySnapshot snapshot) {
    if (snapshot.docs.isEmpty) {
      setState(() => _hasMore = false);
      return;
    }

    _lastDocument = snapshot.docs.last;
    _documentSnapshots.addAll(snapshot.docs);

    final newNotifications = snapshot.docs
        .map((doc) => AppNotification.fromFirestore(doc))
        .toList();

    setState(() => _notifications.addAll(newNotifications));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico Completo'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            tooltip: 'Limpar histórico antigo',
            onPressed: _showCleanupDialog,
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _notifications.isEmpty) {
      return _buildLoading();
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            !_isLoading &&
            _hasMore) {
          _loadMoreNotifications();
        }
        return false;
      },
      child: Column(
        children: [
          _buildStatsHeader(),
          Expanded(child: _buildNotificationsList()),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Carregando histórico...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'Nenhuma notificação no histórico',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'As notificações aparecerão aqui conforme forem recebidas',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return FutureBuilder<Map<String, int>>(
      future: _notificationService.getNotificationStats(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        final stats = snapshot.data!;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border(bottom: BorderSide(color: Colors.blue[100]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', stats['total'] ?? 0, Icons.all_inbox),
              _buildStatItem(
                'Não Lidas',
                stats['unread'] ?? 0,
                Icons.mark_email_unread,
              ),
              _buildStatItem(
                'Esta Semana',
                stats['thisWeek'] ?? 0,
                Icons.calendar_view_week,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue[700]),
        SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.blue[600])),
      ],
    );
  }

  Widget _buildNotificationsList() {
    final groupedNotifications = NotificationUtils.groupNotificationsByDate(
      _notifications,
    );
    final groups = groupedNotifications.entries.toList();

    return RefreshIndicator(
      onRefresh: _refreshData,
      child: ListView.builder(
        itemCount: groups.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == groups.length) {
            return _buildLoadMoreIndicator();
          }

          final group = groups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGroupHeader(group.key),
              ...group.value
                  .map((notification) => _buildNotificationItem(notification))
                  .toList(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700]),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete, color: Colors.white),
            SizedBox(width: 8),
            Text('Deletar', style: TextStyle(color: Colors.white)),
            SizedBox(width: 16),
          ],
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
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
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: notification.read
                  ? FontWeight.normal
                  : FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(notification.message),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 12, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    notification.fromUserName,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Spacer(),
                  Text(
                    DateFormat('HH:mm').format(notification.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          trailing: notification.read
              ? null
              : Icon(Icons.circle, color: Colors.blue, size: 8),
          onTap: () => _showNotificationDetails(notification),
          onLongPress: () => _showActionMenu(notification),
        ),
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : _hasMore
            ? TextButton(
                onPressed: _loadMoreNotifications,
                child: Text('Carregar mais'),
              )
            : Text(
                'Não há mais notificações',
                style: TextStyle(color: Colors.grey),
              ),
      ),
    );
  }

  void _showActionMenu(AppNotification notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Ver detalhes'),
              onTap: () {
                Navigator.pop(context);
                _showNotificationDetails(notification);
              },
            ),
            ListTile(
              leading: Icon(
                notification.read
                    ? Icons.mark_email_unread
                    : Icons.mark_email_read,
              ),
              title: Text(
                notification.read ? 'Marcar como não lida' : 'Marcar como lida',
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleReadStatus(notification);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Deletar', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(notification);
              },
            ),
          ],
        ),
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
              _buildDetailItem('Título', notification.title),
              _buildDetailItem('Mensagem', notification.message),
              _buildDetailItem('Tipo', _getTypeText(notification.type)),
              _buildDetailItem('Prioridade', notification.priority),
              _buildDetailItem(
                'Status',
                notification.read ? 'Lida' : 'Não lida',
              ),
              _buildDetailItem('Remetente', notification.fromUserName),
              _buildDetailItem(
                'Data de Criação',
                DateFormat('dd/MM/yyyy HH:mm').format(notification.createdAt),
              ),
              if (notification.expiresAt != null)
                _buildDetailItem(
                  'Expira em',
                  DateFormat(
                    'dd/MM/yyyy HH:mm',
                  ).format(notification.expiresAt!),
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
                          _buildDetailItem(entry.key, entry.value.toString()),
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
          if (!notification.read)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _markAsRead(notification);
              },
              child: Text('Marcar como Lida'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _refreshData() async {
    setState(() {
      _notifications.clear();
      _documentSnapshots.clear();
      _lastDocument = null;
      _hasMore = true;
    });

    await _loadInitialNotifications();
  }

  void _toggleReadStatus(AppNotification notification) {
    if (notification.read) {
      // Para marcar como não lida, precisaríamos de um método específico
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

  void _deleteNotification(AppNotification notification) async {
    final originalIndex = _notifications.indexWhere(
      (n) => n.id == notification.id,
    );

    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });

    try {
      await _notificationService.deleteNotification(notification.id);
    } catch (e) {
      // Se der erro, readiciona a notificação
      if (originalIndex != -1) {
        setState(() {
          _notifications.insert(originalIndex, notification);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao deletar notificação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(AppNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deletar Notificação?'),
        content: Text(
          'Tem certeza que deseja deletar esta notificação? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteNotification(notification);
            },
            child: Text('Deletar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limpar Histórico Antigo?'),
        content: Text(
          'Esta ação irá remover notificações com mais de 30 dias. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cleanupOldNotifications();
            },
            child: Text('Limpar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _cleanupOldNotifications() async {
    try {
      await _notificationService.deleteOldNotifications(days: 30);
      await _refreshData(); // Recarregar os dados

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Histórico antigo limpo com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao limpar histórico: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'message':
        return 'Mensagem';
      case 'friend_request':
        return 'Solicitação de Amizade';
      case 'system':
        return 'Sistema';
      case 'like':
        return 'Curtida';
      case 'comment':
        return 'Comentário';
      default:
        return type;
    }
  }
}
