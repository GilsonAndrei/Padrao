import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/core/themes/app_theme.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/views/notifications/notification_history_page.dart';
import 'package:projeto_padrao/views/notifications/notifications_page.dart';
import 'package:projeto_padrao/widgets/permission_widget.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../app/app_widget.dart';
import '../../enums/permissao_usuario.dart';
import '../../services/notification/notification_service.dart';
import '../../services/notification/web_notification_service.dart'; // ✅ NOVO

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _setupNotificationListener();
  }

  void _setupNotificationListener() {
    // ✅ CONDICIONAL: Web vs Mobile
    if (kIsWeb) {
      final webService = WebNotificationService();
      webService.notificationStream.listen((message) {
        _handleNotificationClick(message);
      });
    } else {
      final notificationService = Provider.of<NotificationService>(
        NavigationService.context!,
        listen: false,
      );

      notificationService.notificationStream.listen((message) {
        _handleNotificationClick(message);
      });
    }
  }

  /*void _handleWebNotificationClick(Map<String, dynamic> message) {
    final type = message['data']?['type'] ?? message['type'];
    final data = message['data'] ?? {};

    print('🌐 Notificação WEB clicada: $type');

    switch (type) {
      case 'message':
        _abrirTelaMensagem(data);
        break;
      case 'friend_request':
        _abrirSolicitacoesAmizade(data);
        break;
      default:
        _verNotificacoes();
        break;
    }
  }*/

  // ✅ SIMPLIFICADO: Um handler único
  void _handleNotificationClick(dynamic message) {
    print('🎯 Notificação clicada - Navegando para tela...');

    // Navegar diretamente para a tela de notificações
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => NotificationsPage()),
      );
    });
  }

  // ✅ NOVOS MÉTODOS PARA ABRIR TELAS ESPECÍFICAS
  void _abrirTelaMensagem(Map<String, dynamic> data) {
    final chatId = data['chatId'];
    if (chatId != null) {
      // Navegar para tela de chat específico
      _showEmDesenvolvimento('Chat: $chatId');
    } else {
      // Navegar para lista de mensagens
      _showEmDesenvolvimento('Lista de Mensagens');
    }
  }

  void _abrirSolicitacoesAmizade(Map<String, dynamic> data) {
    final requestId = data['friendRequestId'];
    if (requestId != null) {
      // Navegar para detalhes da solicitação
      _showEmDesenvolvimento('Solicitação: $requestId');
    } else {
      // Navegar para lista de solicitações
      _showEmDesenvolvimento('Solicitações de Amizade');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    // ✅ CONDICIONAL: Não usar Provider para NotificationService na Web
    dynamic notificationService;
    if (kIsWeb) {
      notificationService = WebNotificationService();
    } else {
      notificationService = Provider.of<NotificationService>(context);
    }

    if (authController.usuarioLogado == null && !authController.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NavigationService.navigateReplacement(AppRoutes.login);
      });

      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Redirecionando para login...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppTheme.createGradientAppBar(
        title: authController.usuarioLogado != null
            ? 'Olá, ${authController.usuarioLogado!.nome.split(' ').first}!'
            : 'Página Home',
        actions: [
          _buildNotificationBadge(notificationService),
          PopupMenuButton<String>(
            icon: authController.usuarioLogado?.fotoUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(
                      authController.usuarioLogado!.fotoUrl!,
                    ),
                    radius: 16,
                  )
                : Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
            onSelected: (value) {
              _handleMenuSelection(value, authController, context);
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'header',
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authController.usuarioLogado?.nome ?? 'Usuário',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        authController.usuarioLogado?.email ?? '',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'notifications',
                  child: Row(
                    children: [
                      Icon(Icons.notifications, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text('Notificações'),
                      SizedBox(width: 8),
                      _buildNotificationCount(notificationService),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: AppColors.primary),
                      const SizedBox(width: 8),
                      const Text('Meu Perfil'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: AppColors.secondary),
                      const SizedBox(width: 8),
                      const Text('Configurações'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: AppColors.error),
                      const SizedBox(width: 8),
                      const Text('Sair'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _buildBody(authController, notificationService),
      floatingActionButton: _buildFloatingActionButton(authController),
      drawer: _buildDrawer(authController, notificationService),
    );
  }

  // ✅ NOVO: Widget separado para contador de notificações
  Widget _buildNotificationCount(dynamic notificationService) {
    if (kIsWeb) {
      final webService = notificationService as WebNotificationService;
      return StreamBuilder<int>(
        stream: webService.getUnreadCount(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          if (count == 0) return SizedBox();

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 9 ? '9+' : count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      );
    } else {
      final mobileService = notificationService as NotificationService;
      return StreamBuilder<int>(
        stream: mobileService.getUnreadCount(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          if (count == 0) return SizedBox();

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count > 9 ? '9+' : count.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildNotificationBadge(dynamic notificationService) {
    if (kIsWeb) {
      final webService = notificationService as WebNotificationService;
      return StreamBuilder<int>(
        stream: webService.getUnreadCount(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () => _verNotificacoes(),
                tooltip: 'Notificações',
              ),
              if (count > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    } else {
      final mobileService = notificationService as NotificationService;
      return StreamBuilder<int>(
        stream: mobileService.getUnreadCount(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () => _verNotificacoes(),
                tooltip: 'Notificações',
              ),
              if (count > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }
  }

  Widget _buildDrawer(
    AuthController authController,
    dynamic notificationService,
  ) {
    final usuario = authController.usuarioLogado;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade700, Colors.blue.shade400],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 30, color: Colors.blue),
                ),
                SizedBox(height: 10),
                Text(
                  usuario?.nome ?? 'Usuário',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  usuario?.email ?? '',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                _buildDrawerNotificationCount(notificationService, usuario),
              ],
            ),
          ),

          _buildDrawerSection(
            title: 'NOTIFICAÇÕES',
            children: [
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                title: Text(
                  'Minhas Notificações',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  'Ver todas as notificações',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: _buildDrawerNotificationBadge(notificationService),
                onTap: () {
                  Navigator.pop(context);
                  _verNotificacoes();
                },
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
              ),

              _buildDrawerItem(
                icon: Icons.history,
                title: 'Histórico',
                subtitle: 'Histórico de notificações',
                onTap: () {
                  Navigator.pop(context);
                  _verHistoricoNotificacoes();
                },
              ),
            ],
          ),

          AdminOnlyWidget(
            usuario: usuario,
            child: _buildDrawerSection(
              title: 'GESTÃO DO SISTEMA',
              children: [
                _buildDrawerItem(
                  icon: Icons.people,
                  title: 'Gerenciar Usuários',
                  subtitle: 'Cadastrar e editar usuários',
                  onTap: () {
                    Navigator.pop(context);
                    AppPages.navigateTo(context, AppRoutes.users);
                  },
                  badge: 'Admin',
                ),
                _buildDrawerItem(
                  icon: Icons.manage_accounts,
                  title: 'Gerenciar Perfis',
                  subtitle: 'Configurar perfis e permissões',
                  onTap: () {
                    Navigator.pop(context);
                    AppPages.navigateTo(context, AppRoutes.profiles);
                  },
                  badge: 'Admin',
                ),
              ],
            ),
          ),

          _buildDrawerSection(
            title: 'OPERACIONAL',
            children: [
              AnyPermissionWidget(
                usuario: usuario,
                permissoes: [
                  PermissaoUsuario.cadastrarPedidos,
                  PermissaoUsuario.editarPedidos,
                  PermissaoUsuario.visualizarCadastro,
                ],
                child: _buildDrawerItem(
                  icon: Icons.shopping_cart,
                  title: 'Pedidos',
                  subtitle: 'Gerenciar pedidos',
                  onTap: () {
                    Navigator.pop(context);
                    _showEmDesenvolvimento('Pedidos');
                  },
                  badge: 'Pedidos',
                ),
                fallback: const SizedBox.shrink(),
              ),
              _buildDrawerItem(
                icon: Icons.people_outline,
                title: 'Clientes',
                subtitle: 'Gerenciar clientes',
                onTap: () {
                  Navigator.pop(context);
                  _showEmDesenvolvimento('Clientes');
                },
              ),
            ],
          ),

          SinglePermissionWidget(
            usuario: usuario,
            permissao: PermissaoUsuario.visualizarRelatorios,
            child: _buildDrawerSection(
              title: 'RELATÓRIOS',
              children: [
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Relatórios',
                  subtitle: 'Relatórios do sistema',
                  onTap: () {
                    Navigator.pop(context);
                    _showEmDesenvolvimento('Relatórios');
                  },
                  badge: 'Relatórios',
                ),
              ],
            ),
            fallback: const SizedBox.shrink(),
          ),

          AdminOnlyWidget(
            usuario: usuario,
            child: _buildDrawerSection(
              title: 'CONFIGURAÇÕES',
              children: [
                _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Configurações',
                  subtitle: 'Configurações do sistema',
                  onTap: () {
                    Navigator.pop(context);
                    _verConfiguracoes();
                  },
                ),
              ],
            ),
            fallback: const SizedBox.shrink(),
          ),

          _buildDrawerSection(
            title: 'SUPORTE',
            children: [
              _buildDrawerItem(
                icon: Icons.help,
                title: 'Ajuda',
                subtitle: 'Central de ajuda',
                onTap: () {
                  Navigator.pop(context);
                  _showEmDesenvolvimento('Ajuda');
                },
              ),
            ],
          ),

          SizedBox(height: 20),
          Divider(),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Versão 1.0.0',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ NOVO: Widget para contador no drawer header
  Widget _buildDrawerNotificationCount(
    dynamic notificationService,
    Usuario? usuario,
  ) {
    if (kIsWeb) {
      final webService = notificationService as WebNotificationService;
      return StreamBuilder<int>(
        stream: webService.getUnreadCount(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;
          return Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  usuario?.perfil.nome ?? 'Perfil',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              SizedBox(width: 8),
              if (unreadCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount não lida${unreadCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    } else {
      final mobileService = notificationService as NotificationService;
      return StreamBuilder<int>(
        stream: mobileService.getUnreadCount(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;
          return Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  usuario?.perfil.nome ?? 'Perfil',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              SizedBox(width: 8),
              if (unreadCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$unreadCount não lida${unreadCount > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }
  }

  // ✅ NOVO: Widget para badge no drawer item
  Widget _buildDrawerNotificationBadge(dynamic notificationService) {
    if (kIsWeb) {
      final webService = notificationService as WebNotificationService;
      return StreamBuilder<int>(
        stream: webService.getUnreadCount(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          if (count == 0) return SizedBox();

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      );
    } else {
      final mobileService = notificationService as NotificationService;
      return StreamBuilder<int>(
        stream: mobileService.getUnreadCount(),
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          if (count == 0) return SizedBox();

          return Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildDrawerSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 1.0,
            ),
          ),
        ),
        ...children,
      ],
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
      trailing: badge != null
          ? Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildBody(
    AuthController authController,
    dynamic notificationService,
  ) {
    if (authController.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Carregando...'),
          ],
        ),
      );
    }

    if (authController.usuarioLogado == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.orange),
            SizedBox(height: 20),
            Text(
              'Usuário não encontrado',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                NavigationService.navigateReplacement(AppRoutes.login);
              },
              child: Text('Fazer Login'),
            ),
          ],
        ),
      );
    }

    final usuario = authController.usuarioLogado!;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationsQuickCard(notificationService, usuario),

          Card(
            elevation: 4,
            margin: EdgeInsets.only(bottom: 20),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.verified_user,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bem-vindo ao Sistema!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Sua sessão está ativa e segura.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      AdminOnlyWidget(
                        usuario: usuario,
                        child: _buildQuickActionButton(
                          icon: Icons.people,
                          label: 'Usuários',
                          onTap: () =>
                              AppPages.navigateTo(context, AppRoutes.users),
                          color: Colors.green,
                        ),
                        fallback: const SizedBox.shrink(),
                      ),

                      AdminOnlyWidget(
                        usuario: usuario,
                        child: _buildQuickActionButton(
                          icon: Icons.manage_accounts,
                          label: 'Perfis',
                          onTap: () =>
                              AppPages.navigateTo(context, AppRoutes.profiles),
                          color: Colors.purple,
                        ),
                        fallback: const SizedBox.shrink(),
                      ),

                      _buildQuickActionButton(
                        icon: Icons.notifications,
                        label: 'Notificações',
                        onTap: _verNotificacoes,
                        color: Colors.orange,
                      ),

                      SinglePermissionWidget(
                        usuario: usuario,
                        permissao: PermissaoUsuario.cadastrarPedidos,
                        child: _buildQuickActionButton(
                          icon: Icons.shopping_cart,
                          label: 'Novo Pedido',
                          onTap: () => _showEmDesenvolvimento('Novo Pedido'),
                          color: Colors.orange,
                        ),
                        fallback: const SizedBox.shrink(),
                      ),

                      SinglePermissionWidget(
                        usuario: usuario,
                        permissao: PermissaoUsuario.visualizarRelatorios,
                        child: _buildQuickActionButton(
                          icon: Icons.analytics,
                          label: 'Relatórios',
                          onTap: () => _showEmDesenvolvimento('Relatórios'),
                          color: Colors.red,
                        ),
                        fallback: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações do Usuário',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow('Nome', usuario.nome),
                  _buildInfoRow('Email', usuario.email),
                  _buildInfoRow('Status', usuario.ativo ? 'Ativo' : 'Inativo'),
                  _buildInfoRow(
                    'Email Verificado',
                    usuario.emailVerificado ? 'Sim' : 'Não',
                  ),
                  _buildInfoRow(
                    'Data de Criação',
                    '${usuario.dataCriacao.day}/${usuario.dataCriacao.month}/${usuario.dataCriacao.year}',
                  ),
                ],
              ),
            ),
          ),

          Card(
            elevation: 3,
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Permissões de Acesso',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.security, size: 18, color: Colors.grey),
                    ],
                  ),
                  SizedBox(height: 16),
                  if (usuario.perfil.permissoes.isEmpty)
                    Text(
                      'Nenhuma permissão configurada',
                      style: TextStyle(color: Colors.grey),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: usuario.perfil.permissoes.map((permissao) {
                        return Chip(
                          label: Text(
                            permissao.name.replaceAll('_', ' ').toLowerCase(),
                            style: TextStyle(fontSize: 11),
                          ),
                          backgroundColor: _getPermissionColor(permissao),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsQuickCard(
    dynamic notificationService,
    Usuario usuario,
  ) {
    if (kIsWeb) {
      final webService = notificationService as WebNotificationService;
      return StreamBuilder<int>(
        stream: webService.getUnreadCount(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;
          return _buildQuickCardContent(unreadCount);
        },
      );
    } else {
      final mobileService = notificationService as NotificationService;
      return StreamBuilder<int>(
        stream: mobileService.getUnreadCount(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;
          return _buildQuickCardContent(unreadCount);
        },
      );
    }
  }

  Widget _buildQuickCardContent(int unreadCount) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      color: unreadCount > 0 ? Colors.orange.shade50 : Colors.grey.shade50,
      child: InkWell(
        onTap: _verNotificacoes, // ✅ TORNAR CLICÁVEL
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.notifications,
                color: unreadCount > 0 ? Colors.orange : Colors.grey,
                size: 32,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      unreadCount > 0
                          ? 'Você tem $unreadCount notificação${unreadCount > 1 ? 'es' : ''} não lida${unreadCount > 1 ? 's' : ''}'
                          : 'Nenhuma notificação nova',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: unreadCount > 0
                            ? Colors.orange.shade800
                            : Colors.grey.shade700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      unreadCount > 0
                          ? 'Toque para ver as novidades'
                          : 'Todas as notificações estão em dia',
                      style: TextStyle(
                        fontSize: 12,
                        color: unreadCount > 0
                            ? Colors.orange.shade600
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (unreadCount > 0)
                IconButton(
                  icon: Icon(Icons.arrow_forward, color: Colors.orange),
                  onPressed: _verNotificacoes,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 110,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton(AuthController authController) {
    if (authController.usuarioLogado == null) return null;

    final usuario = authController.usuarioLogado!;

    return AnyPermissionWidget(
      usuario: usuario,
      permissoes: [
        PermissaoUsuario.cadastrarPedidos,
        PermissaoUsuario.administrarUsuarios,
      ],
      child: FloatingActionButton(
        onPressed: () {
          if (kIsWeb) {
            final webService = WebNotificationService();
            webService.debugNotificationSystem();
          }
          enviarNotificacaoParaMim();
          _showQuickActions(context, usuario);
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
      fallback: const SizedBox.shrink(),
    );
  }

  void _showQuickActions(BuildContext context, Usuario usuario) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ações Rápidas',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  AdminOnlyWidget(
                    usuario: usuario,
                    child: _buildQuickActionItem(
                      icon: Icons.person_add,
                      label: 'Novo Usuário',
                      onTap: () {
                        Navigator.pop(context);
                        AppPages.navigateTo(context, AppRoutes.userForm);
                      },
                    ),
                    fallback: const SizedBox.shrink(),
                  ),

                  AdminOnlyWidget(
                    usuario: usuario,
                    child: _buildQuickActionItem(
                      icon: Icons.manage_accounts,
                      label: 'Novo Perfil',
                      onTap: () {
                        Navigator.pop(context);
                        AppPages.navigateTo(context, AppRoutes.profileForm);
                      },
                    ),
                    fallback: const SizedBox.shrink(),
                  ),

                  AdminOnlyWidget(
                    usuario: usuario,
                    child: _buildQuickActionItem(
                      icon: Icons.notification_add,
                      label: 'Enviar Notif.',
                      onTap: () {
                        Navigator.pop(context);
                        _enviarNotificacaoTeste();
                      },
                    ),
                    fallback: const SizedBox.shrink(),
                  ),

                  SinglePermissionWidget(
                    usuario: usuario,
                    permissao: PermissaoUsuario.cadastrarPedidos,
                    child: _buildQuickActionItem(
                      icon: Icons.shopping_cart,
                      label: 'Novo Pedido',
                      onTap: () {
                        Navigator.pop(context);
                        _showEmDesenvolvimento('Novo Pedido');
                      },
                    ),
                    fallback: const SizedBox.shrink(),
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.blue),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPermissionColor(dynamic permissao) {
    final permissaoStr = permissao.toString();
    if (permissaoStr.contains('ADMIN') || permissaoStr.contains('CONFIGURAR')) {
      return Colors.red.shade50;
    } else if (permissaoStr.contains('CADASTRAR') ||
        permissaoStr.contains('EDITAR')) {
      return Colors.green.shade50;
    } else if (permissaoStr.contains('VISUALIZAR')) {
      return Colors.blue.shade50;
    } else {
      return Colors.grey.shade50;
    }
  }

  void _handleMenuSelection(
    String value,
    AuthController authController,
    BuildContext context,
  ) {
    switch (value) {
      case 'notifications':
        _verNotificacoes();
        break;
      case 'profile':
        _verPerfil();
        break;
      case 'settings':
        _verConfiguracoes();
        break;
      case 'logout':
        _confirmarLogout(authController, context);
        break;
    }
  }

  void _showEmDesenvolvimento(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Em desenvolvimento'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _verNotificacoes() {
    // ❌ ANTIGO: _showEmDesenvolvimento('Tela de Notificações');
    // ✅ NOVO: Navegar para tela real
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationsPage()),
    );
  }

  void _verHistoricoNotificacoes() {
    // ❌ ANTIGO: _showEmDesenvolvimento('Histórico de Notificações');
    // ✅ NOVO: Navegar para tela real
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NotificationHistoryPage()),
    );
  }

  void _verPerfil() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando para o perfil...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _verConfiguracoes() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando para configurações...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _enviarNotificacaoTeste() {
    _showEmDesenvolvimento('Envio de Notificação');
  }

  void testarNotificacaoReal() async {
    final notificationService = NotificationService();

    final resultado = await notificationService.sendNotification(
      toUserId: "ZKLlr1X8BuVI2AywmlqdTAEsEWh1", // Seu user ID
      title: "Notificação REAL do Firebase 🚀",
      message: "Esta é uma notificação PUSH real enviada via FCM!",
      type: "system",
      data: {"test": "real", "timestamp": DateTime.now().toString()},
    );

    print('📤 Resultado notificação real: $resultado');
  }

  void enviarNotificacaoParaMim() async {
    print("AAAAAAAAAAAAAAAAAAA");
    final notificationService = NotificationService();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      final resultado = await notificationService.sendNotification(
        toUserId: currentUser.uid, // Enviar para si mesmo
        title: "Teste Personalizado 🧪",
        message: "Funcionando perfeitamente! ✅",
        type: "system",
        data: {"test": true},
      );

      print('Resultado: $resultado');
    }
  }

  void _confirmarLogout(AuthController authController, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Saída'),
        content: Text('Tem certeza que deseja sair do sistema?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await authController.logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sair'),
          ),
        ],
      ),
    );
  }
}
