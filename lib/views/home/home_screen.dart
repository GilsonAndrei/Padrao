import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../app/app_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final authController = Provider.of<AuthController>(context);

    // Verifica se usuário está realmente logado
    if (authController.usuarioLogado == null && !authController.isLoading) {
      // Se não está logado, redireciona para login
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
      appBar: AppBar(
        title: Text(
          authController.usuarioLogado != null
              ? 'Olá, ${authController.usuarioLogado!.nome}!'
              : 'Página Home',
        ),
        backgroundColor: Colors.blue,
        actions: [
          // Menu de usuário
          PopupMenuButton<String>(
            icon: Icon(Icons.account_circle),
            onSelected: (value) {
              _handleMenuSelection(value, authController, context);
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Meu Perfil'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Configurações'),
                    ],
                  ),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Sair'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: _buildBody(authController),
      floatingActionButton: _buildFloatingActionButton(authController),
      drawer: _buildDrawer(authController), // ✅ Drawer adicionado
    );
  }

  // ✅ DRAWER COM MENU DE NAVEGAÇÃO
  Widget _buildDrawer(AuthController authController) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ✅ HEADER DO DRAWER
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
                  authController.usuarioLogado?.nome ?? 'Usuário',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  authController.usuarioLogado?.email ?? '',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    authController.usuarioLogado?.perfil.nome ?? 'Perfil',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // ✅ SEÇÃO: GESTÃO DO SISTEMA
          _buildDrawerSection(
            title: 'GESTÃO DO SISTEMA',
            children: [
              _buildDrawerItem(
                icon: Icons.people,
                title: 'Gerenciar Usuários',
                subtitle: 'Cadastrar e editar usuários',
                onTap: () {
                  Navigator.pop(context); // Fecha o drawer
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

          // ✅ SEÇÃO: OPERACIONAL
          _buildDrawerSection(
            title: 'OPERACIONAL',
            children: [
              _buildDrawerItem(
                icon: Icons.shopping_cart,
                title: 'Pedidos',
                subtitle: 'Gerenciar pedidos',
                onTap: () {
                  Navigator.pop(context);
                  // AppPages.navigateTo(context, AppRoutes.orders);
                  _showEmDesenvolvimento('Pedidos');
                },
                badge: 'Pedidos',
              ),
              _buildDrawerItem(
                icon: Icons.people_outline,
                title: 'Clientes',
                subtitle: 'Gerenciar clientes',
                onTap: () {
                  Navigator.pop(context);
                  // AppPages.navigateTo(context, AppRoutes.customers);
                  _showEmDesenvolvimento('Clientes');
                },
              ),
            ],
          ),

          // ✅ SEÇÃO: RELATÓRIOS
          _buildDrawerSection(
            title: 'RELATÓRIOS',
            children: [
              _buildDrawerItem(
                icon: Icons.analytics,
                title: 'Relatórios',
                subtitle: 'Relatórios do sistema',
                onTap: () {
                  Navigator.pop(context);
                  // AppPages.navigateTo(context, AppRoutes.reports);
                  _showEmDesenvolvimento('Relatórios');
                },
                badge: 'Relatórios',
              ),
            ],
          ),

          // ✅ SEÇÃO: CONFIGURAÇÕES
          _buildDrawerSection(
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

          // ✅ ESPAÇO FINAL
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

  // ✅ SEÇÃO DO DRAWER
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

  // ✅ ITEM DO DRAWER
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

  Widget _buildBody(AuthController authController) {
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
          // ✅ CARD DE BOAS-VINDAS
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
                  // ✅ BOTÕES RÁPIDOS
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildQuickActionButton(
                        icon: Icons.people,
                        label: 'Usuários',
                        onTap: () =>
                            AppPages.navigateTo(context, AppRoutes.users),
                        color: Colors.green,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.manage_accounts,
                        label: 'Perfis',
                        onTap: () =>
                            AppPages.navigateTo(context, AppRoutes.profiles),
                        color: Colors.purple,
                      ),

                      _buildQuickActionButton(
                        icon: Icons.shopping_cart,
                        label: 'Novo Pedido',
                        onTap: () => _showEmDesenvolvimento('Novo Pedido'),
                        color: Colors.orange,
                      ),
                      _buildQuickActionButton(
                        icon: Icons.analytics,
                        label: 'Relatórios',
                        onTap: () => _showEmDesenvolvimento('Relatórios'),
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ✅ INFORMACOES DO USUÁRIO
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

          // ✅ PERMISSÕES DO USUÁRIO
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

  // ✅ BOTÃO DE AÇÃO RÁPIDA
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

    return FloatingActionButton(
      onPressed: () {
        _showQuickActions(context);
      },
      backgroundColor: Colors.blue,
      child: Icon(Icons.add, color: Colors.white),
    );
  }

  // ✅ MENU DE AÇÕES RÁPIDAS DO FAB
  void _showQuickActions(BuildContext context) {
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
                  _buildQuickActionItem(
                    icon: Icons.person_add,
                    label: 'Novo Usuário',
                    onTap: () {
                      Navigator.pop(context);
                      AppPages.navigateTo(context, AppRoutes.userForm);
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.manage_accounts,
                    label: 'Novo Perfil',
                    onTap: () {
                      Navigator.pop(context);
                      AppPages.navigateTo(context, AppRoutes.profileForm);
                    },
                  ),
                  _buildQuickActionItem(
                    icon: Icons.shopping_cart,
                    label: 'Novo Pedido',
                    onTap: () {
                      Navigator.pop(context);
                      _showEmDesenvolvimento('Novo Pedido');
                    },
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

  // ✅ CORES PARA PERMISSÕES
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
