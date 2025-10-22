import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:projeto_padrao/firebase_options.dart';
import 'package:projeto_padrao/services/notification/notification_service.dart';
import 'package:projeto_padrao/services/session/session_expiry_service.dart';
import 'app/app_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// ✅ HANDLER GLOBAL PARA BACKGROUND - DEVE SER UMA FUNÇÃO TOP-LEVEL
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔄 HANDLER BACKGROUND: ${message.messageId}");

  // ✅ INICIALIZAR FIREBASE NO BACKGROUND
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ MOSTRAR NOTIFICAÇÃO LOCAL NO BACKGROUND
  final notificationService = NotificationService();
  //await notificationService._showLocalNotification(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ CONFIGURAR FCM ANTES DE TUDO
  if (!kIsWeb) {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Solicitar permissões
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    print('🌐 Status permissão Firebase: ${settings.authorizationStatus}');

    // ✅ CONFIGURAR BACKGROUND HANDLER CORRETAMENTE
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // ✅ CONFIGURAR OPÇÕES DE NOTIFICAÇÃO EM FOREGROUND
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true, // Mostrar notificação
      badge: true, // Atualizar badge
      sound: true, // Tocar som
    );
  }

  // 👇 INICIAR SERVIÇO DE EXPIRAÇÃO AUTOMÁTICA
  SessionExpiryService.startAutoCleanup();

  // Configurações adicionais podem ser adicionadas aqui
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 50, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Ocorreu um erro inesperado',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                details.exceptionAsString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  };

  runApp(const AppWidget());
}
