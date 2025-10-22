// lib/web/service_worker_web.dart
import 'dart:html' as html;

Future<void> registerServiceWorker() async {
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
}
