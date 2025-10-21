// main.dart
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:projeto_padrao/firebase_options.dart';
import 'package:projeto_padrao/services/session/session_expiry_service.dart';
import 'app/app_widget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Registra explicitamente o Service Worker do Firebase Messaging (ESSENCIAL)
  if (html.window.navigator.serviceWorker != null) {
    try {
      final registration = await html.window.navigator.serviceWorker!.register(
        'firebase-messaging-sw.js',
      );
      print('🌐 Service Worker registrado com sucesso: ${registration.scope}');
    } catch (e) {
      print('❌ Falha ao registrar Service Worker: $e');
    }
  } else {
    print('⚠️ Navegador não suporta Service Workers');
  }

  // ✅ Configura permissão do Firebase Messaging
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  final settings = await messaging.requestPermission();
  print('🌐 Status permissão Firebase: ${settings.authorizationStatus}');

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
