// services/notification/web_notification_service.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:projeto_padrao/app/app_widget.dart';
import 'package:projeto_padrao/views/notifications/notifications_page.dart';

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

      await _setupFirebaseMessaging();
      _setupTokenMonitoring();

      _isInitialized = true;
      print('✅ WebNotificationService inicializado');
    } catch (e) {
      print('❌ Erro WebNotificationService: $e');
    }
  }

  void _setupTokenMonitoring() {
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      final NotificationSettings settings = await _firebaseMessaging
          .requestPermission(alert: true, badge: true, sound: true);

      print('🌐 Status permissão Firebase: ${settings.authorizationStatus}');

      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
        print('🌐 FCM Token obtido: ${token.substring(0, 20)}...');
      }

      _setupMessageListeners();

      print('🎯 Firebase Messaging configurado');
    } catch (e) {
      print('❌ Erro configuração FCM: $e');
    }
  }

  void _setupMessageListeners() {
    // 1. ✅ NOTIFICAÇÕES EM PRIMEIRO PLANO
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('🌐 Notificação em foreground: ${message.messageId}');
      print('📢 Título: ${message.notification?.title}');
      print('📝 Corpo: ${message.notification?.body}');

      final webMessage = {
        'id': message.messageId,
        'title': message.notification?.title ?? 'Nova notificação',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'type': 'foreground',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _notificationStream.add(webMessage);
    });

    // 2. ✅ NOTIFICAÇÕES CLICADAS (O QUE VOCÊ PRECISA)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🎯 NOTIFICAÇÃO CLICADA - Navegando para notificações...');
      print('📢 Título: ${message.notification?.title}');
      print('📝 Corpo: ${message.notification?.body}');

      _notificationStream.add({
        'id': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
        'type': 'clicked',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // ✅ NAVEGAÇÃO PARA TELA DE NOTIFICAÇÕES
      _navigateToNotifications();
    });

    print('✅ Listeners configurados - PRONTOS PARA CLICKS!');
  }

  // ✅ NAVEGAR PARA NOTIFICAÇÕES (FUNCIONA PERFEITAMENTE)
  void _navigateToNotifications() {
    try {
      final context = NavigationService.context;
      if (context != null) {
        print('🧭 Navegando para NotificationsPage...');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => NotificationsPage()));
        });
      } else {
        print('⏳ Contexto não disponível, tentando em 1 segundo...');
        Future.delayed(Duration(seconds: 1), () {
          final newContext = NavigationService.context;
          if (newContext != null) {
            Navigator.of(
              newContext,
            ).push(MaterialPageRoute(builder: (_) => NotificationsPage()));
          } else {
            print('❌ Contexto ainda não disponível após delay');
          }
        });
      }
    } catch (e) {
      print('❌ Erro na navegação: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('usuarios').doc(user.uid).update({
          'fcmToken': token,
          'dataAtualizacao': FieldValue.serverTimestamp(),
        });
        print('✅ Token salvo no Firestore');
      } catch (e) {
        print('❌ Erro ao salvar token: $e');
      }
    }
  }

  // ✅ TESTAR SE ESTÁ FUNCIONANDO
  Future<void> testNotification() async {
    print('\n🧪 TESTANDO NOTIFICAÇÃO WEB');
    print('=' * 35);

    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final result = await sendNotification(
        toUserId: currentUser.uid,
        title: 'Teste Web - Clique em mim!',
        message:
            'Esta notificação deve navegar para a tela de notificações quando clicada!',
        data: {
          'type': 'test',
          'test_id': 'web_test_${DateTime.now().millisecondsSinceEpoch}',
        },
      );

      if (result['success'] == true) {
        print('✅ Notificação de teste ENVIADA com sucesso!');
        print('📋 ID: ${result['notificationId']}');
        print('💡 AGORA: Feche o app, clique na notificação e veja se navega!');
      } else {
        print('❌ Falha no envio: ${result['error']}');
      }
    } else {
      print('❌ Usuário não autenticado para teste');
    }
  }

  // ✅ ENVIAR NOTIFICAÇÃO
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

      print('📤 Enviando notificação para: $toUserId');

      final callable = FirebaseFunctions.instance.httpsCallable(
        'createNotification',
      );

      final payload = <String, dynamic>{
        'toUserId': toUserId,
        'title': title,
        'message': message,
        'type': type,
        'platform': 'web',
        'additionalData': {
          ...?data,
          'fromUserId': currentUser.uid,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        },
      };

      final result = await callable.call(payload);
      print('✅ Notificação enviada com sucesso!');

      return {
        'success': true,
        'notificationId': result.data['notificationId'],
        'message': 'Notificação enviada com sucesso',
      };
    } catch (e) {
      print('❌ Erro ao enviar notificação: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  void dispose() {
    _notificationStream.close();
  }
}
