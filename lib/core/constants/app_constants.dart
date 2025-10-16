// core/constants/app_constants.dart
class AppConstants {
  // Nome do App
  static const String appName = 'Sistema Padrão';

  // Versão
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String themeModeKey = 'theme_mode';

  // Firebase Collections
  static const String usersCollection = 'usuarios';
  static const String profilesCollection = 'perfis';
  static const String permissionsCollection = 'permissoes';

  // Routes
  static const String initialRoute = '/splash';
  static const String loginRoute = '/login';
  static const String homeRoute = '/home';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration splashDuration = Duration(seconds: 2);

  //Duração Sessão
  static const Duration sessionDuration = Duration(hours: 4);

  static const int MAX_LOGIN_ATTEMPTS = 5;
  static const Duration LOCKOUT_DURATION = Duration(minutes: 15);
}

class AppStrings {
  static const String welcome = 'Bem-vindo';
  static const String login = 'Login';
  static const String signup = 'Cadastrar';
  static const String email = 'E-mail';
  static const String password = 'Senha';
  static const String forgotPassword = 'Esqueci minha senha';
  static const String dontHaveAccount = 'Não tem uma conta?';
  static const String alreadyHaveAccount = 'Já tem uma conta?';
}
