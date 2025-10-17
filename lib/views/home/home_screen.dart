import 'package:flutter/material.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/core/themes/app_theme.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/widgets/permission_widget.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../app/app_widget.dart';
import '../../enums/permissao_usuario.dart';

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
      appBar: AppTheme.createGradientAppBar(
        title: authController.usuarioLogado != null
            ? 'Olá, ${authController.usuarioLogado!.nome.split(' ').first}!'
            : 'Página Home',
        actions: [
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
                // Header com informações do usuário
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
      body: _buildBody(authController),
      floatingActionButton: _buildFloatingActionButton(authController),
      drawer: _buildDrawer(authController),
    );
  }

  // ✅ DRAWER COM VALIDAÇÃO DE PERMISSÕES
  Widget _buildDrawer(AuthController authController) {
    final usuario = authController.usuarioLogado;

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
              ],
            ),
          ),

          // ✅ SEÇÃO: GESTÃO DO SISTEMA (APENAS ADMIN)
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

          // ✅ SEÇÃO: OPERACIONAL
          _buildDrawerSection(
            title: 'OPERACIONAL',
            children: [
              // Botão de Pedidos - apenas para quem tem permissão
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

          // ✅ SEÇÃO: RELATÓRIOS (apenas para quem pode visualizar relatórios)
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

          // ✅ SEÇÃO: CONFIGURAÇÕES (apenas para administradores)
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

          // ✅ SEÇÃO: AJUDA (disponível para todos)
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
                  // ✅ BOTÕES RÁPIDOS COM PERMISSÕES
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Botão Usuários - apenas Admin
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

                      // Botão Perfis - apenas Admin
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

                      // Botão Novo Pedido - apenas quem tem permissão
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

                      // Botão Relatórios - apenas quem pode visualizar
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

  // ✅ FLOATING ACTION BUTTON COM PERMISSÕES
  Widget? _buildFloatingActionButton(AuthController authController) {
    if (authController.usuarioLogado == null) return null;

    final usuario = authController.usuarioLogado!;

    // Mostra FAB apenas se o usuário tem alguma permissão de criação
    return AnyPermissionWidget(
      usuario: usuario,
      permissoes: [
        PermissaoUsuario.cadastrarPedidos,
        PermissaoUsuario.administrarUsuarios,
      ],
      child: FloatingActionButton(
        onPressed: () {
          _showQuickActions(context, usuario);
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add, color: Colors.white),
      ),
      fallback: const SizedBox.shrink(),
    );
  }

  // ✅ MENU DE AÇÕES RÁPIDAS DO FAB COM PERMISSÕES
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
                  // Novo Usuário - apenas Admin
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

                  // Novo Perfil - apenas Admin
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

                  // Novo Pedido - apenas quem tem permissão
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
