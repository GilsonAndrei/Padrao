// routes/route_guard.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:projeto_padrao/core/themes/app_colors.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/services/session/session_service.dart';
import 'package:provider/provider.dart';
import '../controllers/auth/auth_controller.dart';
import '../views/auth/login_screen.dart';
import '../views/home/home_screen.dart';

class RouteGuard {
  static bool _isInitialCheck = false;

  // Tela de Splash - AGORA É "PREPARANDO AMBIENTE"
  static Widget splashScreen() {
    return FutureBuilder<bool>(
      future: _initializeApp(),
      builder: (context, snapshot) {
        final authController = Provider.of<AuthController>(
          context,
          listen: false,
        );

        if (kDebugMode) {
          print('🔄 [ROUTE_GUARD] Estado: ${snapshot.connectionState}');
          print(
            '👤 [ROUTE_GUARD] Usuário: ${authController.usuarioLogado != null}',
          );
          print('⏳ [ROUTE_GUARD] Carregando: ${authController.isLoading}');
        }

        // Mostra splash enquanto inicializa
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildEnvironmentLoadingScreen();
        }

        if (snapshot.hasError) {
          if (kDebugMode) {
            print('❌ [ROUTE_GUARD] Erro na inicialização: ${snapshot.error}');
          }
          return LoginScreen();
        }

        // Verifica se tem usuário logado após inicialização
        if (authController.usuarioLogado != null && !authController.isLoading) {
          if (kDebugMode) {
            print('✅ [ROUTE_GUARD] Redirecionando para HOME');
          }
          return const HomePage();
        } else {
          if (kDebugMode) {
            print('🔐 [ROUTE_GUARD] Redirecionando para LOGIN');
          }
          return LoginScreen();
        }
      },
    );
  }

  // 🎭 TELA DE "PREPARANDO AMBIENTE"
  static Widget _buildEnvironmentLoadingScreen() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🔹 Logo do Sistema
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.security_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'Sistema Padrão',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),

            const SizedBox(height: 16),

            Text(
              'Preparando ambiente...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Carregando permissões e configurações',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textDisabled,
              ),
            ),

            const SizedBox(height: 32),

            // 🔹 Loading específico para ambiente
            SizedBox(
              width: 120,
              child: Column(
                children: [
                  LinearProgressIndicator(
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Verificando acesso...',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textDisabled,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔄 INICIALIZAÇÃO DO APP
  static Future<bool> _initializeApp() async {
    if (_isInitialCheck) return false;
    _isInitialCheck = true;

    if (kDebugMode) {
      print('🚀 [ROUTE_GUARD] Preparando ambiente...');
    }

    try {
      // Simula carregamento de permissões e configurações
      await Future.delayed(const Duration(milliseconds: 1500));
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ROUTE_GUARD] Erro ao preparar ambiente: $e');
      }
      return false;
    }
  }

  // Rota protegida
  static Widget protectedRoute({
    required Widget child,
    List<PermissaoUsuario> requiredPermissions = const [],
    bool requireAuth = true,
    bool checkSession = true,
  }) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        // Se ainda está carregando, mostra loading
        if (authController.isLoading) {
          return _buildLoadingScreen('Verificando acesso...');
        }

        // 👇 REGISTRAR ATIVIDADE APENAS SE JÁ ESTIVER LOGADO
        if (authController.usuarioLogado != null) {
          authController.recordUserActivity();
        }

        // Verifica se a sessão expirou
        if (checkSession && SessionService.isSessionExpired()) {
          _forceLogout(context, authController);
          return LoginScreen();
        }

        // Atualiza atividade do usuário
        SessionService.updateLastActivity();

        // Verificações de autenticação
        if (requireAuth && authController.usuarioLogado == null) {
          return LoginScreen();
        }

        if (requireAuth && !authController.usuarioLogado!.ativo) {
          return _buildAccessDeniedScreen('Conta desativada');
        }

        // Verificação de permissões
        if (requireAuth && requiredPermissions.isNotEmpty) {
          final hasPermission = _checkPermissions(
            authController.usuarioLogado!,
            requiredPermissions,
          );

          if (!hasPermission) {
            _logSecurityEvent(
              'Tentativa de acesso não autorizado',
              authController.usuarioLogado!,
            );
            return _buildAccessDeniedScreen('Permissão negada');
          }
        }

        return child;
      },
    );
  }

  // 🎨 TELA DE LOADING ESTILIZADA
  static Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _checkPermissions(
    Usuario usuario,
    List<PermissaoUsuario> required,
  ) {
    return required.every(
      (permission) => usuario.perfil.permissoes.contains(permission),
    );
  }

  static void _forceLogout(
    BuildContext context,
    AuthController authController,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      authController.logout();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Sessão expirada. Faça login novamente.'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
    });
  }

  static void _logSecurityEvent(String event, Usuario usuario) {
    if (kDebugMode) {
      print('🔒 [SEGURANÇA] $event - Usuário: ${usuario.email}');
    }
  }

  static Widget _buildAccessDeniedScreen(String message) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acesso Negado'),
        backgroundColor: AppColors.error,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block_rounded, size: 80, color: AppColors.error),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navega para home ou login
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  static bool hasPermission(
    BuildContext context,
    List<PermissaoUsuario> requiredPermissions,
  ) {
    final authController = Provider.of<AuthController>(context, listen: false);

    if (authController.usuarioLogado == null) return false;

    return requiredPermissions.every(
      (permission) =>
          authController.usuarioLogado!.perfil.permissoes.contains(permission),
    );
  }
}
