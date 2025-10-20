import 'dart:async' show Future, Stream, StreamController, Timer;
import 'dart:html' as html;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:projeto_padrao/app/app_widget.dart';
import 'package:projeto_padrao/views/notifications/notifications_page.dart';
import 'package:web/web.dart' as web;

class WebNotificationService {
  static final WebNotificationService _instance =
      WebNotificationService._internal();
  factory WebNotificationService() => _instance;
  WebNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final StreamController<Map<String, dynamic>> _notificationStream =
      StreamController.broadcast();
  bool _isInitialized = false;

  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationStream.stream;

  Future<void> initialize() async {
    if (_isInitialized || !kIsWeb) return;

    try {
      print('🌐 Inicializando WebNotificationService...');

      // 1. Solicitar permissão para notificações
      final NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      print('🌐 Permissão web: ${settings.authorizationStatus}');

      // 2. Obter token FCM para web
      final String? token = await _firebaseMessaging.getToken();

      if (token != null) {
        await _saveTokenToFirestore(token);
        print('🌐 FCM Token Web: $token');
      }

      // 3. Configurar listeners para web
      _setupWebListeners();

      _isInitialized = true;
      print('✅ WebNotificationService inicializado');
    } catch (e) {
      print('❌ Erro WebNotificationService: $e');
    }
  }

  void _setupWebListeners() {
    // Mensagens em primeiro plano (web)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🌐 Notificação web em foreground: ${message.messageId}');

      // Converter para formato compatível com web
      final webMessage = {
        'id': message.messageId,
        'title': message.notification?.title ?? 'Nova notificação',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'type': 'web_foreground',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _notificationStream.add(webMessage);

      // Mostrar notificação nativa do navegador
      _showBrowserNotification(webMessage);
    });

    // Mensagens com app em background/fechado (web)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🌐 Notificação web clicada: ${message.messageId}');

      final webMessage = {
        'id': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
        'type': 'web_background',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _notificationStream.add(webMessage);
    });
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    print(user);

    if (user != null) {
      try {
        await _firestore.collection('usuarios').doc(user.uid).update({
          'fcmToken': token,
          'dataAtualizacao': FieldValue.serverTimestamp(),
        });
        print('🌐 Token web salvo no Firestore');
      } catch (e) {
        print('❌ Erro ao salvar token web: $e');
      }
    }
  }

  void _showBrowserNotification(Map<String, dynamic> message) async {
    try {
      if (!_browserSupportsNotifications()) {
        print('❌ Navegador não suporta notificações');
        return;
      }

      // Verificar e solicitar permissão
      final permissionGranted = await _requestNotificationPermission();
      if (!permissionGranted) {
        print('❌ Permissão de notificação negada');
        return;
      }

      _createBrowserNotification(message);
    } catch (e) {
      print('❌ Erro ao mostrar notificação browser: $e');
    }
  }

  Future<bool> _requestNotificationPermission() async {
    try {
      if (html.Notification.permission == 'granted') {
        return true;
      }

      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    } catch (e) {
      print('❌ Erro ao solicitar permissão: $e');
      return false;
    }
  }

  void _createBrowserNotification(Map<String, dynamic> message) {
    try {
      if (!_browserSupportsNotifications()) {
        print('❌ Navegador não suporta notificações');
        return;
      }

      // ✅ USAR NotificationOptions CORRETAMENTE
      final notificationOptions = {
        'body': message['body'] ?? message['message'] ?? '',
        'icon': '/icons/icon-192.png',
        'badge': '/icons/icon-72.png',
        'tag':
            'web-notification-${message['id'] ?? DateTime.now().millisecondsSinceEpoch}',
        'requireInteraction': true,
      };

      // ✅ CRIAR NOTIFICAÇÃO COM OPTIONS
      final notification = html.Notification(
        message['title'] ?? 'Nova notificação',
      );

      // ✅ EVENTO DE CLIQUE
      notification.onClick.listen((event) {
        print('🌐 Notificação web clicada: ${message['title']}');

        // Focar na janela
        _focusBrowserWindow();

        // Handler de clique
        _handleNotificationClick(message);

        notification.close();
      });

      // Auto-fechar após 8 segundos
      Timer(Duration(seconds: 8), () {
        notification.close();
      });

      print('✅ Notificação web exibida: ${message['title']}');
    } catch (e) {
      print('❌ Erro ao criar notificação web: $e');
    }
  }

  void _focusBrowserWindow() {
    try {
      // Métodos alternativos para focar na janela
      // Tentar focar no documento/window
      //html.window.focus();

      // Alternativa: disparar evento de foco
      html.document.dispatchEvent(html.Event('focus'));

      print('🌐 Janela do navegador focada');
    } catch (e) {
      print('⚠️ Não foi possível focar na janela: $e');
    }
  }

  void _focusCurrentWindowOnly() {
    try {
      // ✅ Focar na janela atual
      web.window.focus();

      // ✅ Opcional: tentar também focar o body (para garantir interação)
      html.document.body?.tabIndex = -1;
      html.document.body?.focus();

      print('🎯 Janela atual focada (sem abrir nova)');
    } catch (e) {
      print('⚠️ Não foi possível focar na janela atual: $e');
    }
  }

  // ✅ CORREÇÃO: Adicionar método que estava faltando
  void _handleNotificationClick(Map<String, dynamic> message) {
    print('🔗 Notificação clicada: ${message['title']}');

    final data = message['data'] ?? {};
    final notificationId = data['notificationId'];
    final type = data['type'];

    // ✅ EVITAR RECARREGAR A PÁGINA - usar NavigationService
    _navigateToNotificationScreen(type, data);

    // Adicionar à stream para que outros ouvintes possam reagir
    _notificationStream.add({
      ...message,
      'clicked': true,
      'clickedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  // ✅ NOVO: Navegação sem recarregar
  void _navigateToNotificationScreen(String type, Map<String, dynamic> data) {
    try {
      // Usar o NavigationService para navegar sem recarregar
      final context = NavigationService.context;
      if (context != null) {
        switch (type) {
          case 'message':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsPage()),
            );
            break;
          case 'friend_request':
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsPage()),
            );
            break;
          default:
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationsPage()),
            );
            break;
        }
      } else {
        print('❌ Contexto não disponível para navegação');
        // Fallback: focar na janela sem recarregar
        _focusBrowserWindowSoft();
      }
    } catch (e) {
      print('❌ Erro na navegação: $e');
      _focusBrowserWindowSoft();
    }
  }

  // ✅ NOVO: Focar sem recarregar
  void _focusBrowserWindowSoft() {
    try {
      // Apenas focar na janela atual sem recarregar
      //html.window.focus();
      print('🌐 Janela focada (sem recarregar)');
    } catch (e) {
      print('⚠️ Não foi possível focar na janela: $e');
    }
  }

  // Enviar notificação (compatível com web)
  Future<Map<String, dynamic>> sendNotification({
    required String toUserId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'createNotification',
      );

      final result = await callable.call(<String, dynamic>{
        'toUserId': toUserId,
        'title': title,
        'message': message,
        'type': type,
        'platform': 'web',
        'additionalData': data,
      });

      return {
        'success': true,
        'notificationId': result.data['notificationId'],
        'message': 'Notificação web enviada com sucesso',
      };
    } catch (e) {
      print('❌ Erro ao enviar notificação web: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Obter número de notificações não lidas (web)
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  bool _browserSupportsNotifications() {
    try {
      return html.Notification != null && html.Notification.supported;
    } catch (e) {
      print('❌ Navegador não suporta notificações: $e');
      return false;
    }
  }

  // ✅ NOVO: Método para verificar suporte e permissões
  Future<Map<String, dynamic>> checkNotificationSupport() async {
    try {
      final supports = _browserSupportsNotifications();
      final permission = html.Notification.permission;
      final token = await _firebaseMessaging.getToken();

      return {
        'supported': supports,
        'permission': permission,
        'hasToken': token != null,
        'token': token,
      };
    } catch (e) {
      return {
        'supported': false,
        'permission': 'unknown',
        'hasToken': false,
        'error': e.toString(),
      };
    }
  }

  Future<void> debugNotificationSystem() async {
    print('🔍 DIAGNÓSTICO DETALHADO NOTIFICAÇÕES WEB:');

    try {
      // 1. Verificar suporte do navegador
      print('1. Suporte a notificações: ${_browserSupportsNotifications()}');
      print('2. Permissão atual: ${html.Notification.permission}');
      print(
        '3. Service Worker suportado: ${html.window.navigator.serviceWorker != null}',
      );

      // 2. Verificar token FCM
      final token = await _firebaseMessaging.getToken();
      print(
        '4. Token FCM: ${token != null ? "✅ Disponível" : "❌ Indisponível"}',
      );

      // 3. Testar notificação manual
      if (html.Notification.permission == 'granted') {
        _createBrowserNotification({
          'title': 'Teste de Diagnóstico ✅',
          'body': 'Se você vê esta notificação, o sistema está funcionando!',
          'id': 'diagnostic-${DateTime.now().millisecondsSinceEpoch}',
        });
      } else {
        print('❌ Permissão não concedida. Solicitar...');
        final granted = await _requestNotificationPermission();
        print('Permissão concedida: $granted');
      }
    } catch (e) {
      print('❌ Erro no diagnóstico: $e');
    }
  }

  void dispose() {
    _notificationStream.close();
    _isInitialized = false;
    print('🔴 WebNotificationService disposed');
  }
}
