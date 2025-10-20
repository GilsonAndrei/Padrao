import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projeto_padrao/services/notification/notification_service.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  User? get user => _auth.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Meu Perfil')),
      body: user == null ? _buildNotLoggedIn() : _buildProfile(),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Usuário não logado', style: TextStyle(fontSize: 18)),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar login
            },
            child: Text('Fazer Login'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user!.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

        return ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildUserHeader(userData),
            SizedBox(height: 24),
            _buildNotificationSettings(),
            SizedBox(height: 24),
            _buildAccountActions(),
          ],
        );
      },
    );
  }

  Widget _buildUserHeader(Map<String, dynamic> userData) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: userData['photoURL'] != null
                  ? NetworkImage(userData['photoURL']!)
                  : null,
              child: userData['photoURL'] == null
                  ? Icon(Icons.person, size: 40, color: Colors.white)
                  : null,
              backgroundColor: Colors.blue,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userData['name'] ?? 'Usuário',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    userData['email'] ?? user!.email ?? '',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Chip(
                    label: Text(
                      userData['fcmToken'] != null
                          ? 'Notificações Ativas'
                          : 'Notificações Inativas',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: userData['fcmToken'] != null
                        ? Colors.green
                        : Colors.orange,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Configurações de Notificação',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            SwitchListTile(
              title: Text('Notificações Push'),
              subtitle: Text('Receber notificações em tempo real'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Som'),
              subtitle: Text('Reproduzir som nas notificações'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Vibração'),
              subtitle: Text('Vibrar ao receber notificações'),
              value: true,
              onChanged: (value) {},
            ),
            SwitchListTile(
              title: Text('Notificações em Background'),
              subtitle: Text('Receber notificações com o app em segundo plano'),
              value: true,
              onChanged: (value) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountActions() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ações da Conta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildActionTile(
              icon: Icons.notifications_active,
              title: 'Testar Notificação',
              subtitle: 'Enviar notificação de teste para este dispositivo',
              onTap: _sendTestNotificationToSelf,
            ),
            _buildActionTile(
              icon: Icons.refresh,
              title: 'Atualizar Token FCM',
              subtitle: 'Forçar atualização do token de notificação',
              onTap: _refreshFCMToken,
            ),
            _buildActionTile(
              icon: Icons.cleaning_services,
              title: 'Limpar Todas as Notificações',
              subtitle: 'Remover todo o histórico de notificações',
              onTap: _clearAllNotifications,
            ),
            _buildActionTile(
              icon: Icons.logout,
              title: 'Sair',
              subtitle: 'Fazer logout da aplicação',
              onTap: _signOut,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Function() onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      subtitle: Text(subtitle),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: color),
      onTap: onTap,
    );
  }

  Future<void> _sendTestNotificationToSelf() async {
    final result = await _notificationService.sendNotificationWithRetry(
      toUserId: user!.uid,
      title: 'Teste de Notificação ✅',
      message: 'Esta é uma notificação de teste enviada para você mesmo.',
      type: 'system',
      data: {'test': true, 'timestamp': DateTime.now().millisecondsSinceEpoch},
    );

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notificação de teste enviada com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar notificação: ${result['message']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _refreshFCMToken() async {
    // O token é atualizado automaticamente, mas podemos forçar uma verificação
    await _notificationService.initialize();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Token FCM atualizado'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<void> _clearAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limpar Todas as Notificações?'),
        content: Text(
          'Esta ação irá remover permanentemente todo o seu histórico de notificações. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Limpar Tudo', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _notificationService.clearAllNotifications();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Todas as notificações foram removidas'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao limpar notificações: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      // O redirecionamento será tratado pelo stream de auth
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer logout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
