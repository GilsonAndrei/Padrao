import 'package:flutter/material.dart';
import 'package:projeto_padrao/routes/route_guard.dart';
import 'package:projeto_padrao/views/auth/forgot_password_screen.dart';
import 'package:projeto_padrao/views/auth/login_screen.dart';
import 'package:projeto_padrao/views/auth/signup_screen.dart';
import 'package:projeto_padrao/views/home/home_screen.dart';
import 'package:projeto_padrao/views/perfil/perfil_form_screen.dart';
import 'package:projeto_padrao/views/perfil/perfil_list_screen.dart';
import 'package:projeto_padrao/views/usuario/usuario_form_screen.dart';
import 'package:projeto_padrao/views/usuario/usuario_list_screen.dart';

class AppRoutes {
  // Auth Routes
  static const String splash = '/splash';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';

  // Main Routes
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Feature Routes
  static const String orders = '/orders';
  static const String customers = '/customers';
  static const String reports = '/reports';

  // User Management Routes
  static const String users = '/users';
  static const String userForm = '/users/form';
  static const String userEdit = '/users/edit';

  // Profile Management Routes
  static const String profiles = '/profiles';
  static const String profileForm = '/profiles/form';
  static const String profileEdit = '/profiles/edit';
}

class AppPages {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      // ✅ Auth Routes
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => RouteGuard.splashScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => SignUpScreen());

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());

      // ✅ Main Routes
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => RouteGuard.protectedRoute(child: const HomePage()),
        );

      // ✅ User Management Routes
      case AppRoutes.users:
        return MaterialPageRoute(
          builder: (_) => RouteGuard.protectedRoute(child: UsuarioListScreen()),
        );

      case AppRoutes.userForm:
        return MaterialPageRoute(
          builder: (_) => RouteGuard.protectedRoute(child: UsuarioFormScreen()),
        );

      case AppRoutes.userEdit:
        return MaterialPageRoute(
          builder: (_) => RouteGuard.protectedRoute(
            child: UsuarioFormScreen(usuario: args as dynamic),
          ),
        );

      // ✅ Profile Management Routes
      case AppRoutes.profiles:
        return MaterialPageRoute(
          builder: (_) => RouteGuard.protectedRoute(child: PerfilListScreen()),
        );

      case AppRoutes.profileForm:
        return MaterialPageRoute(
          builder: (_) => RouteGuard.protectedRoute(child: PerfilFormScreen()),
        );

      case AppRoutes.profileEdit:
        return MaterialPageRoute(
          builder: (_) => RouteGuard.protectedRoute(
            child: PerfilFormScreen(perfil: args as dynamic),
          ),
        );

      // ✅ Rota não encontrada
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Rota não encontrada: ${settings.name}')),
          ),
        );
    }
  }

  // ✅ Método auxiliar para navegação com arguments
  static void navigateTo(
    BuildContext context,
    String route, {
    dynamic arguments,
  }) {
    Navigator.of(context).pushNamed(route, arguments: arguments);
  }

  // ✅ Método para replace (substituir tela atual)
  static void replaceWith(
    BuildContext context,
    String route, {
    dynamic arguments,
  }) {
    Navigator.of(context).pushReplacementNamed(route, arguments: arguments);
  }

  // ✅ Método para navegar e remover todas as telas
  static void navigateAndRemoveUntil(
    BuildContext context,
    String route, {
    dynamic arguments,
  }) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(route, (route) => false, arguments: arguments);
  }
}
