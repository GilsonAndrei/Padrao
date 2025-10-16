// views/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../app/app_widget.dart';

// Importe as telas que criamos
import '../usuarios/usuario_list_screen.dart';
import '../perfis/perfil_list_screen.dart';

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
              : 'Sistema Padrão',
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
          // Card de boas-vindas
          Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.verified_user, color: Colors.green, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Bem-vindo ao Sistema!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Sua sessão está ativa e segura.',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Módulos do Sistema
          Card(
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Módulos do Sistema',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildModuleButton(
                        icon: Icons.people,
                        label: 'Usuários',
                        color: Colors.blue,
                        onTap: () => _abrirUsuarios(),
                        enabled: true,
                      ),
                      _buildModuleButton(
                        icon: Icons.assignment_ind,
                        label: 'Perfis',
                        color: Colors.green,
                        onTap: () => _abrirPerfis(),
                        enabled: true,
                      ),
                      _buildModuleButton(
                        icon: Icons.bar_chart,
                        label: 'Relatórios',
                        color: Colors.orange,
                        onTap: () => _abrirRelatorios(),
                        enabled: usuario.perfil.temPermissao(
                          PermissaoUsuario.visualizarRelatorios,
                        ),
                      ),
                      _buildModuleButton(
                        icon: Icons.settings,
                        label: 'Configurações',
                        color: Colors.purple,
                        onTap: () => _abrirConfiguracoes(),
                        enabled: usuario.perfil.temPermissao(
                          PermissaoUsuario.configurarSistema,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Informações do usuário
          Card(
            elevation: 3,
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
                  _buildInfoRow('Perfil', usuario.perfil.nome),
                  _buildInfoRow(
                    'Data de Criação',
                    '${usuario.dataCriacao.day}/${usuario.dataCriacao.month}/${usuario.dataCriacao.year}',
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Permissões do usuário
          Card(
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Permissões de Acesso',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            permissao.nome,
                            style: TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.blue[50],
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Ações rápidas
          Card(
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
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
                      _buildActionButton(
                        icon: Icons.security,
                        label: 'Alterar Senha',
                        onTap: () => _alterarSenha(authController),
                      ),
                      _buildActionButton(
                        icon: Icons.person,
                        label: 'Meu Perfil',
                        onTap: () => _verPerfil(),
                      ),
                      _buildActionButton(
                        icon: Icons.history,
                        label: 'Atividades',
                        onTap: () => _verAtividades(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 20),

          // Debug info (apenas para desenvolvimento)
          if (authController.usuarioLogado != null) ...[
            Card(
              color: Colors.grey[100],
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔧 Informações de Debug',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'User ID: ${usuario.id}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'Perfil: ${usuario.perfil.nome}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        print('📋 Dados completos do usuário:');
                        print(usuario.toMap().toString());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        foregroundColor: Colors.grey[700],
                        elevation: 0,
                        minimumSize: Size(0, 30),
                      ),
                      child: Text(
                        'Ver Dados no Console',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 110,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: enabled ? color.withOpacity(0.3) : Colors.grey[300]!,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: enabled ? color : Colors.grey),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: enabled ? color : Colors.grey,
              ),
            ),
            if (!enabled) ...[
              SizedBox(height: 4),
              Text(
                'Sem acesso',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(AuthController authController) {
    if (authController.usuarioLogado == null) return null;

    return FloatingActionButton(
      onPressed: () {
        // Ação do FAB - Abrir criação rápida
        _showQuickActions(context);
      },
      backgroundColor: Colors.blue,
      child: Icon(Icons.add, color: Colors.white),
    );
  }

  void _showQuickActions(BuildContext context) {
    final authController = Provider.of<AuthController>(context, listen: false);
    final usuario = authController.usuarioLogado!;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Criação Rápida',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (usuario.perfil.temPermissao(
                  PermissaoUsuario.administrarUsuarios,
                ))
                  _buildQuickActionButton(
                    icon: Icons.person_add,
                    label: 'Novo Usuário',
                    onTap: () {
                      Navigator.pop(context);
                      _abrirUsuarios();
                    },
                  ),
                if (usuario.perfil.temPermissao(
                  PermissaoUsuario.administrarUsuarios,
                ))
                  _buildQuickActionButton(
                    icon: Icons.assignment_ind,
                    label: 'Novo Perfil',
                    onTap: () {
                      Navigator.pop(context);
                      _abrirPerfis();
                    },
                  ),
              ],
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[100]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: Colors.blue),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
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
        _abrirConfiguracoes();
        break;
      case 'logout':
        _confirmarLogout(authController, context);
        break;
    }
  }

  // === NOVOS MÉTODOS PARA ABRIR AS TELAS ===

  void _abrirUsuarios() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UsuarioListScreen()),
    );
  }

  void _abrirPerfis() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PerfilListScreen()),
    );
  }

  void _abrirRelatorios() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Módulo de relatórios em desenvolvimento...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _abrirConfiguracoes() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Módulo de configurações em desenvolvimento...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _alterarSenha(AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alterar Senha'),
        content: Text('Funcionalidade em desenvolvimento...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
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

  void _verAtividades() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navegando para atividades...'),
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
              // Logout redireciona automaticamente para login
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Sair'),
          ),
        ],
      ),
    );
  }
}
