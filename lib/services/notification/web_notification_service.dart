import 'dart:async';
import 'dart:js_util' as js_util;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:js/js.dart';
import 'package:projeto_padrao/app/app_widget.dart';
import 'package:projeto_padrao/views/notifications/notifications_page.dart';

// ✅ INTEROP SIMPLIFICADO
@JS()
external dynamic get Notification;

@JS('Notification.permission')
external String get notificationPermission;

@JS('Notification.requestPermission')
external Future<dynamic> requestNotificationPermission();

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
      // ✅ ADICIONAR COMUNICAÇÃO COM SERVICE WORKER
      // _setupServiceWorkerCommunication();

      _isInitialized = true;
      print('✅ WebNotificationService inicializado');
    } catch (e) {
      print('❌ Erro WebNotificationService: $e');
    }
  } // Monitorar mudanças no token

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
        print('🌐 FCM Token obtido');
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

      final webMessage = {
        'id': message.messageId,
        'title': message.notification?.title ?? 'Nova notificação',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'type': 'foreground',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      _notificationStream.add(webMessage);
      _showNativeNotification(webMessage);
    });

    // 2. ✅ NOTIFICAÇÕES CLICADAS - SEM NENHUMA NAVEGAÇÃO
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🌐 Notificação clicada - APENAS LOGGING');

      // ✅ APENAS ADICIONAR À STREAM - SEM NAVEGAR
      _notificationStream.add({
        'id': message.messageId,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
        'type': 'clicked',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      // ❌ REMOVIDO COMPLETAMENTE: _navigateToNotifications()
      // ❌ REMOVIDO COMPLETAMENTE: _focusCurrentWindow()
      // ❌ REMOVIDO COMPLETAMENTE: Qualquer navegação automática
    });

    print('✅ Listeners configurados - SEM NAVEGAÇÃO AUTOMÁTICA');
  }

  // ✅ MÉTODO COMPLETAMENTE CORRIGIDO
  void _showNativeNotification(Map<String, dynamic> message) {
    try {
      print('🔄 Criando notificação nativa...');

      if (Notification == null) {
        print('❌ Notification API não disponível');
        return;
      }

      if (notificationPermission != 'granted') {
        print('❌ Permissão não concedida: $notificationPermission');
        return;
      }

      // ✅ CORREÇÃO: Converter dados manualmente para evitar problemas com jsify
      final dataJson = _convertDataToJson(message['data'] ?? {});

      final script =
          '''
        try {
    console.log('🎯 Criando notificação...');
    
    const options = {
      body: "${_escapeString(message['body']?.toString() ?? '')}",
      icon: "/icons/icon-192.png",
      badge: "/icons/icon-72.png",
      tag: "notification-${message['id']}",
      requireInteraction: false, // ✅ Deixa usuário decidir
    };
    
    const notification = new Notification("${_escapeString(message['title']?.toString() ?? 'Nova notificação')}", options);
    
    console.log('✅ Notificação criada');
    
    notification.onclick = function(event) {
      console.log('🌐 Notificação clicada - Apenas fechando');
      notification.close();
      // ❌ SEM window.focus() - deixa o browser decidir
    };
    
    // Auto-fechar após 10 segundos
    setTimeout(() => {
      try {
        notification.close();
      } catch(e) {
        console.log('⚠️ Erro ao fechar notificação:', e);
      }
    }, 10000);
    
  } catch(error) {
    console.error('❌ Erro ao criar notificação:', error);
  }
''';

      print('📜 Executando script JavaScript...');
      _executeJavaScript(script);
    } catch (e) {
      print('❌ Erro ao mostrar notificação: $e');
    }
  }

  // ✅ CONVERTER DADOS PARA JSON MANUALMENTE
  String _convertDataToJson(Map<String, dynamic> data) {
    try {
      if (data.isEmpty) return '{}';

      final entries = data.entries
          .map((entry) {
            final key = entry.key;
            final value = entry.value is String
                ? '"${_escapeString(entry.value)}"'
                : entry.value;
            return '"$key": $value';
          })
          .join(',');

      return '{$entries}';
    } catch (e) {
      print('❌ Erro ao converter dados para JSON: $e');
      return '{}';
    }
  }

  // ✅ ESCAPAR STRING PARA JAVASCRIPT
  String _escapeString(String text) {
    return text
        .replaceAll(r'$', r'\$')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\r')
        .replaceAll('\t', r'\t');
  }

  // ✅ EXECUTAR JAVASCRIPT DE FORMA SEGURA
  void _executeJavaScript(String script) {
    try {
      // Método 1: Usar eval diretamente
      js_util.callMethod(js_util.globalThis, 'eval', [script]);
    } catch (e) {
      print('❌ Erro ao executar JavaScript: $e');

      // Método 2: Tentar criar elemento script
      try {
        final scriptElement =
            '''
          try {
            $script
          } catch(jsError) {
            console.error('Erro JavaScript:', jsError);
          }
        ''';
        js_util.callMethod(js_util.globalThis, 'eval', [scriptElement]);
      } catch (e2) {
        print('❌ Erro alternativo também falhou: $e2');
      }
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
      } catch (e) {
        print('❌ Erro ao salvar token: $e');
      }
    }
  }

  void _handleNotificationClick(RemoteMessage message) {
    print('🌐 Notificação clicada - Apenas logging');

    // ✅ APENAS LOG, SEM NAVEGAR
    _notificationStream.add({
      'id': message.messageId,
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
      'type': 'clicked',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    // ❌ REMOVIDO: _navigateToNotifications() e _focusCurrentWindow()
  }

  void _navigateToNotifications() {
    try {
      final context = NavigationService.context;
      if (context != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NotificationsPage()),
          );
        });
      }
    } catch (e) {
      print('❌ Erro navegação: $e');
    }
  }

  // ✅ MÉTODO DE TESTE MELHORADO
  Future<void> testNotification() async {
    print('\n🧪 TESTE DE NOTIFICAÇÃO');
    print('=' * 30);

    // 1. Teste de notificação simples primeiro
    print('1. 🎯 Testando notificação SIMPLES...');
    _testSimpleNotification();

    // 2. Aguardar um pouco e testar notificação completa
    print('2. ⏳ Aguardando 2 segundos...');
    await Future.delayed(Duration(seconds: 2));

    print('3. 🎯 Testando notificação COMPLETA...');
    _showNativeNotification({
      'title': '✅ Teste Completo',
      'body': 'Esta é uma notificação de teste completa!',
      'id': 'test-complete-${DateTime.now().millisecondsSinceEpoch}',
      'data': {
        'type': 'test',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    });

    // 3. Testar Firebase
    print('4. 📤 Testando Firebase Functions...');
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      final result = await sendNotification(
        toUserId: currentUser.uid,
        title: 'Teste Firebase',
        message: 'Notificação via Firebase Functions',
      );
      print(
        '   - Firebase: ${result['success'] ? '✅' : '❌ ${result['error']}'}',
      );
    }

    print('🎉 TESTE COMPLETADO');
  }

  // ✅ TESTE SIMPLES - MÍNIMO NECESSÁRIO
  void _testSimpleNotification() {
    try {
      final simpleScript = '''
        try {
          console.log('🧪 TESTE SIMPLES: Verificando Notification API...');
          
          if (typeof Notification === 'undefined') {
            console.error('❌ Notification API não disponível');
            return;
          }
          
          console.log('✅ Notification API disponível');
          console.log('📋 Permissão atual:', Notification.permission);
          
          if (Notification.permission === 'granted') {
            console.log('🎯 Tentando criar notificação simples...');
            
            const notification = new Notification('Teste Simples ✅', {
              body: 'Notificação de teste simples funcionando!',
              icon: '/icons/icon-192.png'
            });
            
            notification.onclick = function() {
              console.log('✅ Notificação simples clicada!');
              notification.close();
              window.focus();
            };
            
            setTimeout(() => notification.close(), 5000);
            console.log('✅ Notificação simples criada com sucesso!');
            
          } else {
            console.log('❌ Permissão não concedida para notificação simples');
          }
          
        } catch(error) {
          console.error('❌ Erro no teste simples:', error);
        }
      ''';

      _executeJavaScript(simpleScript);
    } catch (e) {
      print('❌ Erro no teste simples: $e');
    }
  }

  // ✅ MÉTODO SENDNOTIFICATION MELHORADO
  // ✅ MÉTODO SENDNOTIFICATION CORRIGIDO
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

      print('📤 ENVIANDO NOTIFICAÇÃO VIA FIREBASE FUNCTIONS...');

      final callable = FirebaseFunctions.instance.httpsCallable(
        'createNotification',
      );

      // ✅ CORREÇÃO: CONVERTER VALORES PARA STRING NO FLUTTER TAMBÉM
      final stringifiedData = {};
      if (data != null) {
        data.forEach((key, value) {
          // Converter para string se não for string
          stringifiedData[key] = value is String ? value : value.toString();
        });
      }

      final payload = <String, dynamic>{
        'toUserId': toUserId,
        'title': title,
        'message': message,
        'type': type,
        'platform': 'web',
        'additionalData': {
          ...stringifiedData,
          //'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'fromUserId': currentUser.uid,
          'timestamp': DateTime.now().millisecondsSinceEpoch
              .toString(), // ✅ STRING
        },
      };

      print('   - Payload corrigido: $payload');

      final result = await callable.call(payload);
      print('   - ✅ Resposta do Firebase: ${result.data}');

      return {
        'success': true,
        'notificationId': result.data['notificationId'],
        'message': 'Notificação enviada com sucesso',
      };
    } catch (e) {
      print('❌ ERRO ao enviar notificação: $e');
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
    _isInitialized = false;
  }

  // ✅ ADICIONE ESTE MÉTODO PARA DIAGNÓSTICO
  Future<void> debugSendNotification() async {
    print('\n🔍 DIAGNÓSTICO SENDNOTIFICATION');
    print('=' * 40);

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('❌ Usuário não autenticado');
      return;
    }

    // 1. ✅ VERIFICAR TOKEN DO USUÁRIO ATUAL
    print('1. 🔍 Verificando token do usuário atual...');
    final userDoc = await _firestore
        .collection('usuarios')
        .doc(currentUser.uid)
        .get();
    final userToken = userDoc.data()?['fcmToken'];
    print('   - Token no Firestore: ${userToken != null ? "✅" : "❌"}');
    if (userToken != null) {
      print('   - Token: ${userToken.substring(0, 20)}...');
    }

    // 2. ✅ VERIFICAR TOKEN ATUAL DO FIREBASE
    print('2. 🔍 Verificando token atual do Firebase...');
    final currentToken = await _firebaseMessaging.getToken();
    print('   - Token atual: ${currentToken != null ? "✅" : "❌"}');
    if (currentToken != null) {
      print('   - Token atual: ${currentToken.substring(0, 20)}...');
    }

    // 3. ✅ COMPARAR TOKENS
    if (userToken != null && currentToken != null) {
      print('3. 🔍 Comparando tokens...');
      if (userToken == currentToken) {
        print('   - ✅ Tokens são iguais');
      } else {
        print('   - ❌ Tokens DIFERENTES! Atualizando...');
        await _saveTokenToFirestore(currentToken);
      }
    }

    // 4. ✅ TESTAR ENVIO DIRETO
    print('4. 🧪 Testando envio de notificação...');
    final result = await sendNotification(
      toUserId: currentUser.uid,
      title: 'Teste de Diagnóstico',
      message: 'Esta notificação deve aparecer no seu PC!',
      data: {'type': 'diagnostic', 'test': 'true'},
    );

    print('5. 📊 Resultado do envio:');
    print('   - Sucesso: ${result['success']}');
    print('   - Notification ID: ${result['notificationId']}');
    if (result['error'] != null) {
      print('   - Erro: ${result['error']}');
    }

    // 6. ✅ VERIFICAR NO FIRESTORE
    if (result['success'] == true && result['notificationId'] != null) {
      print('6. 🔍 Verificando notificação no Firestore...');
      await Future.delayed(Duration(seconds: 2)); // Aguardar processamento

      final notificationDoc = await _firestore
          .collection('notifications')
          .doc(result['notificationId'])
          .get();

      if (notificationDoc.exists) {
        print('   - ✅ Notificação salva no Firestore');
        final data = notificationDoc.data();
        print('   - Status: ${data?['status']}');
        print('   - Platform: ${data?['platform']}');
        print('   - Sent: ${data?['sent']}');
      } else {
        print('   - ❌ Notificação NÃO encontrada no Firestore');
      }
    }

    // 7. ✅ TESTE ALTERNATIVO: Notificação local
    print('7. 🎯 Testando notificação local...');
    _showNativeNotification({
      'title': 'Teste Local ✅',
      'body': 'Se esta aparece, o problema é no Firebase',
      'id': 'local-test-${DateTime.now().millisecondsSinceEpoch}',
      'data': {'type': 'local_test'},
    });

    print('\n🎯 DIAGNÓSTICO COMPLETO');
  }

  // ✅ NO WEBNOTIFICATIONSERVICE - ADICIONE ESTE MÉTODO
  void _setupServiceWorkerCommunication() {
    try {
      // ✅ INFORMAR AO SERVICE WORKER QUE O APP ESTÁ PRONTO
      final script = '''
      if (navigator.serviceWorker && navigator.serviceWorker.controller) {
        navigator.serviceWorker.controller.postMessage({
          type: 'APP_READY',
          ready: true,
          timestamp: Date.now()
        });
        console.log('📨 App informou ao Service Worker que está pronto');
      }
    ''';

      _executeJavaScript(script);

      // ✅ OUVINTE PARA MENSAGENS DO SERVICE WORKER
      final messageScript = '''
      navigator.serviceWorker.addEventListener('message', function(event) {
        console.log('📨 Mensagem do Service Worker:', event.data);
        
        if (event.data.type === 'NOTIFICATION_CLICK') {
          console.log('🎯 Service Worker solicitou navegação para notificações');
          // O Flutter vai lidar com a navegação internamente
        }
      });
    ''';

      _executeJavaScript(messageScript);
    } catch (e) {
      print('⚠️ Erro na comunicação com Service Worker: $e');
    }
  }
}
