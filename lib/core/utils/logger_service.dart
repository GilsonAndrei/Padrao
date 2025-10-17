// utils/logger_service.dart
class LoggerService {
  static void info(String tag, String message) {
    print('ℹ️ [$tag] $message');
  }

  static void success(String tag, String message) {
    print('✅ [$tag] $message');
  }

  static void warning(String tag, String message) {
    print('⚠️ [$tag] $message');
  }

  static void error(String tag, String message, {dynamic error}) {
    print('❌ [$tag] $message');
    if (error != null) print('   🔍 Erro detalhado: $error');
  }

  static void security(String tag, String message) {
    print('🚨 [$tag] $message');
  }

  static void debug(String tag, String message) {
    print('🐛 [$tag] $message');
  }
}
