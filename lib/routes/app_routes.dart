// routes/app_routes.dart
import 'package:flutter/material.dart';
import 'package:projeto_padrao/routes/route_guard.dart';
import 'package:projeto_padrao/views/auth/forgot_password_screen.dart';
import 'package:projeto_padrao/views/auth/login_screen.dart';
import 'package:projeto_padrao/views/auth/signup_screen.dart';
import 'package:projeto_padrao/views/home/home_screen.dart';

// routes/app_routes.dart
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
  static const String users = '/users';
}

class AppPages {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => RouteGuard.splashScreen());

      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());

      case AppRoutes.signup:
        return MaterialPageRoute(builder: (_) => SignUpScreen());

      case AppRoutes.forgotPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => RouteGuard.protectedRoute(child: const HomePage()),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(child: Text('Rota não encontrada: ${settings.name}')),
          ),
        );
    }
  }
}
