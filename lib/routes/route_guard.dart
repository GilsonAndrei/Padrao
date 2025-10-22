// routes/route_guard.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/services/session/session_service.dart';
import 'package:provider/provider.dart';
import '../controllers/auth/auth_controller.dart';
import '../views/auth/login_screen.dart';
import '../views/home/home_screen.dart';

class RouteGuard {
  // Tela de Splash - CORRIGIDO
  static Widget splashScreen() {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        print('🔄 [ROUTE_GUARD] Verificando estado da sessão...');
        print(
          '👤 [ROUTE_GUARD] Usuário logado: ${authController.usuarioLogado != null}',
        );
        print('⏳ [ROUTE_GUARD] Carregando: ${authController.isLoading}');

        // ✅ SE JÁ CARREGOU: Decide imediatamente
        if (!authController.isLoading) {
          if (authController.usuarioLogado != null) {
            print('✅ [ROUTE_GUARD] Usuário LOGADO - Redirecionando para HOME');
            return const HomePage();
          } else {
            print(
              '🔐 [ROUTE_GUARD] Usuário NÃO LOGADO - Redirecionando para LOGIN',
            );
            return LoginScreen();
          }
        }

        // ✅ SE AINDA ESTÁ CARREGANDO: Mostra splash com timeout
        return _SplashWithTimeout(authController: authController);
      },
    );
  }

  // Widget com timeout para evitar travamento
  static Widget _SplashWithTimeout({required AuthController authController}) {
    return FutureBuilder(
      future: Future.delayed(
        const Duration(seconds: 10),
      ), // Timeout de 10 segundos
      builder: (context, snapshot) {
        // Se passou o timeout, força decisão
        if (snapshot.connectionState == ConnectionState.done) {
          print('⏰ [ROUTE_GUARD] Timeout - Forçando decisão');

          if (authController.usuarioLogado != null) {
            return const HomePage();
          } else {
            return LoginScreen();
          }
        }

        // Enquanto espera, mostra splash normal
        return _buildSplashScreen();
      },
    );
  }

  // Tela de Loading
  static Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Rota protegida - CORRIGIDA
  static Widget protectedRoute({
    required Widget child,
    List<PermissaoUsuario> requiredPermissions = const [],
    bool requireAuth = true,
  }) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        // 👇 REGISTRAR ATIVIDADE DO USUÁRIO
        authController.recordUserActivity();
        SessionService.updateLastActivity();

        // Verificações simplificadas
        if (requireAuth && authController.usuarioLogado == null) {
          return LoginScreen();
        }

        if (requireAuth && !authController.usuarioLogado!.ativo) {
          return _buildAccessDeniedScreen(
            context,
            'Conta desativada',
          ); // ✅ CORRIGIDO
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
            return _buildAccessDeniedScreen(
              context,
              'Permissão negada',
            ); // ✅ CORRIGIDO
          }
        }

        return child;
      },
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

  static void _logSecurityEvent(String event, Usuario usuario) {
    print('🔒 [SEGURANÇA] $event - Usuário: ${usuario.email}');
  }

  // Tela de Splash
  static Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100),
            const SizedBox(height: 20),
            const Text(
              'Sistema Padrão',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  // Tela de Acesso Negado - CORRIGIDA (adicionado parâmetro context)
  static Widget _buildAccessDeniedScreen(BuildContext context, String message) {
    // ✅ CORRIGIDO
    return Scaffold(
      appBar: AppBar(title: const Text('Acesso Negado')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navega para home
                Navigator.of(context).pushReplacementNamed('/home');
              },
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

/*// routes/route_guard.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/enums/permissao_usuario.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/services/session/session_service.dart';
import 'package:provider/provider.dart';
import '../controllers/auth/auth_controller.dart';
import '../views/auth/login_screen.dart';
import '../views/home/home_screen.dart';

class RouteGuard {
  // Tela de Splash - Decide para onde redirecionar
  static Widget splashScreen() {
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 2)),
      builder: (context, snapshot) {
        final authController = Provider.of<AuthController>(
          context,
          listen: false,
        );

        print('🔄 [ROUTE_GUARD] Verificando estado da sessão...');
        print(
          '👤 [ROUTE_GUARD] Usuário logado: ${authController.usuarioLogado != null}',
        );
        print('⏳ [ROUTE_GUARD] Carregando: ${authController.isLoading}');

        if (snapshot.connectionState == ConnectionState.done) {
          if (authController.isLoading) {
            // Ainda carregando, mostra loading
            return _buildLoadingScreen('Verificando sessão...');
          }

          if (authController.usuarioLogado != null) {
            print('✅ [ROUTE_GUARD] Redirecionando para HOME');
            return const HomePage();
          } else {
            print('🔐 [ROUTE_GUARD] Redirecionando para LOGIN');
            return LoginScreen();
          }
        }

        return _buildSplashScreen();
      },
    );
  }

  // Tela de Loading
  static Widget _buildLoadingScreen(String message) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Rota protegida - Verifica autenticação e permissões
  static Widget protectedRoute({
    required Widget child,
    List<PermissaoUsuario> requiredPermissions = const [],
    bool requireAuth = true,
    bool checkSession = true,
  }) {
    return Consumer<AuthController>(
      builder: (context, authController, _) {
        // 👇 REGISTRAR ATIVIDADE DO USUÁRIO
        authController.recordUserActivity();
        // Verifica se a sessão expirou
        if (checkSession && SessionService.isSessionExpired()) {
          _forceLogout(context, authController);
          return LoginScreen();
        }

        // Atualiza atividade do usuário
        SessionService.updateLastActivity();

        // Verificações existentes...
        if (requireAuth && authController.usuarioLogado == null) {
          return LoginScreen();
        }

        if (requireAuth && !authController.usuarioLogado!.ativo) {
          return _buildAccessDeniedScreen('Conta desativada');
        }

        // Verificação de permissões melhorada
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
          content: Text('Sessão expirada. Faça login novamente.'),
          backgroundColor: Colors.orange,
        ),
      );
    });
  }

  static void _logSecurityEvent(String event, Usuario usuario) {
    print('🔒 [SEGURANÇA] $event - Usuário: ${usuario.email}');
    // Aqui você pode enviar para um serviço de logging
  }

  // Tela de Splash
  static Widget _buildSplashScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100),
            const SizedBox(height: 20),
            const Text(
              'Sistema Padrão',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  // Tela de Acesso Negado
  static Widget _buildAccessDeniedScreen(String message) {
    return Scaffold(
      appBar: AppBar(title: const Text('Acesso Negado')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.block, size: 80, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Navega para home ou login
              },
              child: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  // Verifica se usuário tem permissão
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

*/























/* EXEMPLO DE USO: // Exemplo de uso em botões ou navegação
ElevatedButton(
  onPressed: () {
    // Navegação simples
    NavigationService.navigateTo(AppRoutes.home);
    
    // Navegação com verificação de permissão
    if (RouteGuard.hasPermission(context, [PermissaoUsuario.visualizarCadastro])) {
      NavigationService.navigateTo(AppRoutes.customers);
    }
  },
  child: const Text('Navegar'),
),

// Em uma rota específica com permissões
RouteGuard.protectedRoute(
  child: const CustomersScreen(),
  requiredPermissions: [PermissaoUsuario.visualizarCadastro],
),*/