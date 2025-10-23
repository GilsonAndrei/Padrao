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
import 'package:projeto_padrao/core/responsive/responsive_layout.dart';
import 'package:projeto_padrao/core/responsive/responsive_utils.dart';
import 'package:projeto_padrao/core/responsive/breakpoints.dart';

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
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text(
                'Redirecionando para login...',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          authController.usuarioLogado != null
              ? 'Olá, ${authController.usuarioLogado!.nome.split(' ').first}!'
              : 'Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: _getResponsiveValue(mobile: 18, tablet: 20, desktop: 22),
          ),
        ),
        actions: [_buildUserMenu(authController)],
      ),
      body: _buildResponsiveBody(authController),
      floatingActionButton: _buildFloatingActionButton(authController),
      drawer: _buildDrawer(authController),
    );
  }

  // ✅ NOVO MÉTODO: Body responsivo com scroll
  Widget _buildResponsiveBody(AuthController authController) {
    return ResponsiveLayout(
      mobile: _buildMobileBody(authController),
      tablet: _buildTabletBody(authController),
      desktop: _buildDesktopBody(authController),
    );
  }

  // ✅ MOBILE COM SCROLL
  Widget _buildMobileBody(AuthController authController) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: 20),
      child: _buildBodyContent(authController),
    );
  }

  // ✅ TABLET COM SCROLL
  Widget _buildTabletBody(AuthController authController) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(24),
      child: _buildBodyContent(authController),
    );
  }

  // ✅ DESKTOP COM SCROLL
  Widget _buildDesktopBody(AuthController authController) {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(32),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 1200),
          child: _buildBodyContent(authController),
        ),
      ),
    );
  }

  Widget _buildUserMenu(AuthController authController) {
    return ResponsiveLayout(
      mobile: _buildMobileUserMenu(authController),
      tablet: _buildTabletUserMenu(authController),
      desktop: _buildDesktopUserMenu(authController),
    );
  }

  Widget _buildMobileUserMenu(AuthController authController) {
    return PopupMenuButton<String>(
      icon: _buildUserAvatar(authController, 20),
      onSelected: (value) {
        _handleMenuSelection(value, authController, context);
      },
      itemBuilder: (BuildContext context) {
        return _buildMenuItems(authController);
      },
    );
  }

  Widget _buildTabletUserMenu(AuthController authController) {
    return PopupMenuButton<String>(
      icon: Row(
        children: [
          _buildUserAvatar(authController, 24),
          const SizedBox(width: 8),
          Text(
            authController.usuarioLogado?.nome.split(' ').first ?? 'Usuário',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          ),
        ],
      ),
      onSelected: (value) {
        _handleMenuSelection(value, authController, context);
      },
      itemBuilder: (BuildContext context) {
        return _buildMenuItems(authController);
      },
    );
  }

  Widget _buildDesktopUserMenu(AuthController authController) {
    return Row(
      children: [
        _buildUserAvatar(authController, 28),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              authController.usuarioLogado?.nome.split(' ').first ?? 'Usuário',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
            Text(
              authController.usuarioLogado?.perfil.nome ?? '',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
          onSelected: (value) {
            _handleMenuSelection(value, authController, context);
          },
          itemBuilder: (BuildContext context) {
            return _buildMenuItems(authController);
          },
        ),
      ],
    );
  }

  Widget _buildUserAvatar(AuthController authController, double iconSize) {
    return authController.usuarioLogado?.fotoUrl != null
        ? CircleAvatar(
            backgroundImage: NetworkImage(
              authController.usuarioLogado!.fotoUrl!,
            ),
            radius: iconSize,
          )
        : Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.person_outline,
              color: AppColors.primary,
              size: iconSize,
            ),
          );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(AuthController authController) {
    return [
      // Header com informações do usuário
      PopupMenuItem<String>(
        value: 'header',
        enabled: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              authController.usuarioLogado?.nome ?? 'Usuário',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              authController.usuarioLogado?.email ?? '',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem<String>(
        value: 'profile',
        child: Row(
          children: [
            Icon(Icons.person, color: AppColors.primary),
            const SizedBox(width: 8),
            const Text('Meu Perfil'),
          ],
        ),
      ),
      PopupMenuItem<String>(
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
      PopupMenuItem<String>(
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
  }

  // ✅ DRAWER PREMIUM
  Widget _buildDrawer(AuthController authController) {
    return ResponsiveLayout(
      mobile: _buildMobileDrawer(authController),
      tablet: _buildTabletDrawer(authController),
      desktop: _buildDesktopDrawer(authController),
    );
  }

  Widget _buildMobileDrawer(AuthController authController) {
    return _buildDrawerContent(authController);
  }

  Widget _buildTabletDrawer(AuthController authController) {
    return SizedBox(width: 280, child: _buildDrawerContent(authController));
  }

  Widget _buildDesktopDrawer(AuthController authController) {
    return SizedBox(width: 320, child: _buildDrawerContent(authController));
  }

  Widget _buildDrawerContent(AuthController authController) {
    final usuario = authController.usuarioLogado;

    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.background.withOpacity(0.98),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ✅ HEADER DO DRAWER PREMIUM
              Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withOpacity(0.9),
                      AppColors.secondary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: _getResponsiveValue(
                        mobile: 25,
                        tablet: 30,
                        desktop: 35,
                      ),
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        size: _getResponsiveValue(
                          mobile: 25,
                          tablet: 30,
                          desktop: 35,
                        ),
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      usuario?.nome ?? 'Usuário',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _getResponsiveValue(
                          mobile: 16,
                          tablet: 18,
                          desktop: 20,
                        ),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      usuario?.email ?? '',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: _getResponsiveValue(
                          mobile: 12,
                          tablet: 14,
                          desktop: 14,
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        usuario?.perfil.nome ?? 'Perfil',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: _getResponsiveValue(
                            mobile: 10,
                            tablet: 12,
                            desktop: 12,
                          ),
                          fontWeight: FontWeight.w500,
                        ),
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
                  icon: Icons.admin_panel_settings,
                  children: [
                    _buildDrawerItem(
                      icon: Icons.people_alt_rounded,
                      title: 'Gerenciar Usuários',
                      subtitle: 'Cadastrar e editar usuários',
                      onTap: () {
                        Navigator.pop(context);
                        AppPages.navigateTo(context, AppRoutes.users);
                      },
                      badge: 'Admin',
                      badgeColor: AppColors.success,
                    ),
                    _buildDrawerItem(
                      icon: Icons.manage_accounts_rounded,
                      title: 'Gerenciar Perfis',
                      subtitle: 'Configurar perfis e permissões',
                      onTap: () {
                        Navigator.pop(context);
                        AppPages.navigateTo(context, AppRoutes.profiles);
                      },
                      badge: 'Admin',
                      badgeColor: AppColors.success,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ SEÇÃO DO DRAWER PREMIUM
  Widget _buildDrawerSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        ...children,
      ],
    );
  }

  // ✅ ITEM DO DRAWER PREMIUM
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
    Color? badgeColor,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          badgeColor?.withOpacity(0.1) ??
                          AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color:
                            badgeColor?.withOpacity(0.3) ??
                            AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 10,
                        color: badgeColor ?? AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(AuthController authController) {
    if (authController.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(
              'Carregando dashboard...',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (authController.usuarioLogado == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.warning),
            SizedBox(height: 20),
            Text(
              'Sessão expirada',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Por favor, faça login novamente',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                NavigationService.navigateReplacement(AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: Text('Fazer Login'),
            ),
          ],
        ),
      );
    }

    final usuario = authController.usuarioLogado!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ CARD DE BOAS-VINDAS PREMIUM
        ResponsiveLayout(
          mobile: _buildWelcomeCardMobile(usuario),
          tablet: _buildWelcomeCardTablet(usuario),
          desktop: _buildWelcomeCardDesktop(usuario),
        ),
        SizedBox(height: 24),

        // ✅ LAYOUT DE CARDS INFORMAÇÕES
        ResponsiveLayout(
          mobile: _buildInfoCardsMobile(usuario),
          tablet: _buildInfoCardsTablet(usuario),
          desktop: _buildInfoCardsDesktop(usuario),
        ),
      ],
    );
  }

  Widget _buildWelcomeCardMobile(Usuario usuario) {
    return _buildWelcomeCard(usuario, crossAxisCount: 2);
  }

  Widget _buildWelcomeCardTablet(Usuario usuario) {
    return _buildWelcomeCard(usuario, crossAxisCount: 3);
  }

  Widget _buildWelcomeCardDesktop(Usuario usuario) {
    return _buildWelcomeCard(usuario, crossAxisCount: 4);
  }

  Widget _buildWelcomeCard(Usuario usuario, {required int crossAxisCount}) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.05),
            AppColors.secondary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified_user_rounded,
                  color: Colors.white,
                  size: _getResponsiveValue(
                    mobile: 24,
                    tablet: 28,
                    desktop: 32,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bem-vindo de volta!',
                      style: TextStyle(
                        fontSize: _getResponsiveValue(
                          mobile: 18,
                          tablet: 20,
                          desktop: 22,
                        ),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Sua sessão está ativa e segura no sistema.',
                      style: TextStyle(
                        fontSize: _getResponsiveValue(
                          mobile: 13,
                          tablet: 14,
                          desktop: 15,
                        ),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          // ✅ BOTÕES RÁPIDOS COM PERMISSÕES
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _buildQuickActions(usuario, crossAxisCount),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuickActions(Usuario usuario, int crossAxisCount) {
    final actions = [
      // Botão Usuários - apenas Admin
      AdminOnlyWidget(
        usuario: usuario,
        child: _buildQuickActionButton(
          icon: Icons.people_alt_rounded,
          label: 'Usuários',
          onTap: () => AppPages.navigateTo(context, AppRoutes.users),
          color: AppColors.success,
        ),
        fallback: const SizedBox.shrink(),
      ),

      // Botão Perfis - apenas Admin
      AdminOnlyWidget(
        usuario: usuario,
        child: _buildQuickActionButton(
          icon: Icons.manage_accounts_rounded,
          label: 'Perfis',
          onTap: () => AppPages.navigateTo(context, AppRoutes.profiles),
          color: AppColors.info,
        ),
        fallback: const SizedBox.shrink(),
      ),

      // Botão Novo Pedido - apenas quem tem permissão
      SinglePermissionWidget(
        usuario: usuario,
        permissao: PermissaoUsuario.cadastrarPedidos,
        child: _buildQuickActionButton(
          icon: Icons.shopping_cart_rounded,
          label: 'Novo Pedido',
          onTap: () => _showEmDesenvolvimento('Novo Pedido'),
          color: AppColors.warning,
        ),
        fallback: const SizedBox.shrink(),
      ),

      // Botão Relatórios - apenas quem pode visualizar
      SinglePermissionWidget(
        usuario: usuario,
        permissao: PermissaoUsuario.visualizarRelatorios,
        child: _buildQuickActionButton(
          icon: Icons.analytics_rounded,
          label: 'Relatórios',
          onTap: () => _showEmDesenvolvimento('Relatórios'),
          color: AppColors.secondary,
        ),
        fallback: const SizedBox.shrink(),
      ),
    ];

    // Filtra ações vazias
    return actions.where((action) => action is! SizedBox).toList();
  }

  Widget _buildInfoCardsMobile(Usuario usuario) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildUserInfoCard(usuario),
          SizedBox(height: 16),
          _buildPermissionsCard(usuario),
        ],
      ),
    );
  }

  Widget _buildInfoCardsTablet(Usuario usuario) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildUserInfoCard(usuario)),
          SizedBox(width: 16),
          Expanded(child: _buildPermissionsCard(usuario)),
        ],
      ),
    );
  }

  Widget _buildInfoCardsDesktop(Usuario usuario) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildUserInfoCard(usuario)),
          SizedBox(width: 24),
          Expanded(flex: 3, child: _buildPermissionsCard(usuario)),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard(Usuario usuario) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Informações do Usuário',
                style: TextStyle(
                  fontSize: _getResponsiveValue(
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow('Nome Completo', usuario.nome),
          _buildInfoRow('E-mail', usuario.email),
          _buildInfoRow('Status', usuario.ativo ? 'Ativo' : 'Inativo'),
          _buildInfoRow(
            'E-mail Verificado',
            usuario.emailVerificado ? 'Verificado' : 'Pendente',
          ),
          _buildInfoRow(
            'Data de Criação',
            '${usuario.dataCriacao.day.toString().padLeft(2, '0')}/${usuario.dataCriacao.month.toString().padLeft(2, '0')}/${usuario.dataCriacao.year}',
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsCard(Usuario usuario) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.security_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Permissões de Acesso',
                style: TextStyle(
                  fontSize: _getResponsiveValue(
                    mobile: 16,
                    tablet: 18,
                    desktop: 20,
                  ),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (usuario.perfil.permissoes.isEmpty)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Text(
                'Nenhuma permissão configurada para este perfil',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: usuario.perfil.permissoes.map((permissao) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPermissionColor(permissao).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getPermissionColor(permissao).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    permissao.name.replaceAll('_', ' ').toLowerCase(),
                    style: TextStyle(
                      fontSize: _getResponsiveValue(
                        mobile: 10,
                        tablet: 11,
                        desktop: 12,
                      ),
                      color: _getPermissionColor(permissao),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ✅ BOTÃO DE AÇÃO RÁPIDA PREMIUM
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: _getResponsiveValue(mobile: 110, tablet: 130, desktop: 150),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: _getResponsiveValue(
                    mobile: 20,
                    tablet: 22,
                    desktop: 24,
                  ),
                  color: color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _getResponsiveValue(
                    mobile: 12,
                    tablet: 13,
                    desktop: 14,
                  ),
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
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
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ FLOATING ACTION BUTTON PREMIUM
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
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add_rounded, color: Colors.white),
      ),
      fallback: const SizedBox.shrink(),
    );
  }

  // ✅ MENU DE AÇÕES RÁPIDAS PREMIUM
  void _showQuickActions(BuildContext context, Usuario usuario) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flash_on_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'Ações Rápidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    // Novo Usuário - apenas Admin
                    AdminOnlyWidget(
                      usuario: usuario,
                      child: _buildQuickActionItem(
                        icon: Icons.person_add_alt_1_rounded,
                        label: 'Novo Usuário',
                        onTap: () {
                          Navigator.pop(context);
                          AppPages.navigateTo(context, AppRoutes.userForm);
                        },
                        color: AppColors.success,
                      ),
                      fallback: const SizedBox.shrink(),
                    ),

                    // Novo Perfil - apenas Admin
                    AdminOnlyWidget(
                      usuario: usuario,
                      child: _buildQuickActionItem(
                        icon: Icons.manage_accounts_rounded,
                        label: 'Novo Perfil',
                        onTap: () {
                          Navigator.pop(context);
                          AppPages.navigateTo(context, AppRoutes.profileForm);
                        },
                        color: AppColors.info,
                      ),
                      fallback: const SizedBox.shrink(),
                    ),

                    // Novo Pedido - apenas quem tem permissão
                    SinglePermissionWidget(
                      usuario: usuario,
                      permissao: PermissaoUsuario.cadastrarPedidos,
                      child: _buildQuickActionItem(
                        icon: Icons.shopping_cart_rounded,
                        label: 'Novo Pedido',
                        onTap: () {
                          Navigator.pop(context);
                          _showEmDesenvolvimento('Novo Pedido');
                        },
                        color: AppColors.warning,
                      ),
                      fallback: const SizedBox.shrink(),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Fechar',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: _getResponsiveValue(mobile: 100, tablet: 110, desktop: 120),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
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
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ MÉTODO AUXILIAR PARA VALORES RESPONSIVOS
  double _getResponsiveValue({
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (Breakpoints.isMobile(width)) return mobile;
    if (Breakpoints.isTablet(width)) return tablet;
    return desktop;
  }

  // ✅ CORES PARA PERMISSÕES
  Color _getPermissionColor(dynamic permissao) {
    final permissaoStr = permissao.toString();
    if (permissaoStr.contains('ADMIN') || permissaoStr.contains('CONFIGURAR')) {
      return AppColors.error;
    } else if (permissaoStr.contains('CADASTRAR') ||
        permissaoStr.contains('EDITAR')) {
      return AppColors.success;
    } else if (permissaoStr.contains('VISUALIZAR')) {
      return AppColors.info;
    } else {
      return AppColors.textSecondary;
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
        content: Row(
          children: [
            Icon(Icons.build_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '$feature - Em desenvolvimento',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.info,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _verPerfil() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.person_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Navegando para o perfil...'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _verConfiguracoes() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.settings_rounded, color: Colors.white),
            SizedBox(width: 8),
            Text('Navegando para configurações...'),
          ],
        ),
        backgroundColor: AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _confirmarLogout(AuthController authController, BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: _getResponsiveValue(
              mobile: MediaQuery.of(context).size.width * 0.8,
              tablet: 400,
              desktop: 450,
            ),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 30,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Confirmar Saída',
                style: TextStyle(
                  fontSize: _getResponsiveValue(
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Tem certeza que deseja sair do sistema?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: _getResponsiveValue(
                    mobile: 14,
                    tablet: 15,
                    desktop: 16,
                  ),
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 24),
              ResponsiveLayout(
                mobile: _buildLogoutButtonsMobile(),
                tablet: _buildLogoutButtonsTablet(),
                desktop: _buildLogoutButtonsDesktop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButtonsMobile() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: AppColors.border),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AuthController>(
                context,
                listen: false,
              ).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Sair do Sistema',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButtonsTablet() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: AppColors.border),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AuthController>(
                context,
                listen: false,
              ).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Sair',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButtonsDesktop() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: AppColors.border),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AuthController>(
                context,
                listen: false,
              ).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Text(
              'Sair do Sistema',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
