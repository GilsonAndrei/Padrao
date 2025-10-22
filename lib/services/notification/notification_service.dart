import 'dart:async';
import 'dart:typed_data';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:projeto_padrao/app/app_widget.dart';
import 'package:projeto_padrao/models/usuario.dart';
import 'package:projeto_padrao/views/notifications/notifications_page.dart';

class NotificationService extends ChangeNotifier {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Instâncias do Firebase
  FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Notificações locais
  late FlutterLocalNotificationsPlugin _localNotifications;

  // Streams e controle de estado
  final StreamController<RemoteMessage> _notificationStream =
      StreamController.broadcast();
  final Map<String, dynamic> _notificationCache = {};
  final List<StreamSubscription> _subscriptions = [];
  bool _isInitialized = false;

  // Getters
  Stream<RemoteMessage> get notificationStream => _notificationStream.stream;
  String? get currentUserId => _auth.currentUser?.uid;

  // Inicialização completa do serviço
  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) return;

    try {
      // ✅ VERIFICAR SE FIREBASE ESTÁ INICIALIZADO
      try {
        Firebase.app();
      } catch (e) {
        print('❌ Firebase não inicializado. Aguardando...');
        await Firebase.initializeApp();
      }

      await _setupFirebaseMessaging();
      await _setupLocalNotifications();
      _setupForegroundNotifications();
      _setupBackgroundHandler();
      _setupTokenMonitoring(); // ✅ ADICIONE ESTA LINHA
      _setupFCMDebug(); // Debug FCM

      _isInitialized = true;
      print('✅ NotificationService inicializado com sucesso');
    } catch (e) {
      print('❌ Erro ao inicializar NotificationService: $e');
      rethrow;
    }
  }

  // Configuração do Firebase Messaging
  Future<void> _setupFirebaseMessaging() async {
    if (kIsWeb) {
      print('🌐 Web: Configuração de FCM limitada');
      return;
    }

    final NotificationSettings settings = await _firebaseMessaging
        .requestPermission(alert: true, badge: true, sound: true);

    print('Status da permissão: ${settings.authorizationStatus}');

    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _updateFCMToken();
  }

  // Atualizar token FCM no Firestore
  Future<void> _updateFCMToken() async {
    try {
      final String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveTokenToFirestore(token);
        print('📱 FCM Token: $token');
      }
    } catch (e) {
      print('❌ Erro ao obter FCM token: $e');
    }
  }

  // Monitorar mudanças no token
  void _setupTokenMonitoring() {
    _firebaseMessaging.onTokenRefresh.listen(_saveTokenToFirestore);
  }

  // Salvar token no Firestore
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
        // Se o documento não existir, criar
        await _firestore.collection('usuarios').doc(user.uid).set({
          'fcmToken': token,
          'email': user.email,
          'nome': user.displayName ?? 'Usuário',
          'ativo': true,
          'emailVerificado': user.emailVerified,
          'isAdmin': false,
          'dataCriacao': FieldValue.serverTimestamp(),
          'dataAtualizacao': FieldValue.serverTimestamp(),
          'perfil': {
            'nome': 'Padrão',
            'descricao': 'Perfil de usuário padrão',
            'permissoes': [],
            'nivelAcesso': 1,
          },
        }, SetOptions(merge: true));
      }
    }
  }

  // ✅ CORRIGIDO: Configurar notificações locais
  Future<void> _setupLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    // Configuração Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuração iOS
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    await _createNotificationChannel();
  }

  // ✅ Handler para notificações clicadas
  static void _onDidReceiveNotificationResponse(NotificationResponse response) {
    print('📱 Notificação local clicada: ${response.payload}');
    // A navegação é tratada no _handleNotificationClick
  }

  // Criar canal de notificação (Android)
  Future<void> _createNotificationChannel() async {
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'Notificações Importantes',
      description: 'Este canal é usado para notificações importantes.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList(const [0, 500, 200, 500]),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
  }

  // ✅ CORRIGIDO: Configurar handlers para foreground
  void _setupForegroundNotifications() {
    print('🎯 CONFIGURANDO LISTENERS FCM...');

    // ✅ LISTENER PARA FOREGROUND - DEVE MOSTRAR NOTIFICAÇÃO
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 FCM RECEBIDO EM FOREGROUND: ${message.messageId}');
        print('📢 Título: ${message.notification?.title}');
        print('📝 Corpo: ${message.notification?.body}');
        print('🔍 Data: ${message.data}');

        // ✅ MOSTRAR NOTIFICAÇÃO LOCAL IMEDIATAMENTE
        _showLocalNotification(message);

        // Adicionar à stream
        _notificationStream.add(message);
      }),
    );

    // ✅ LISTENER PARA QUANDO O USUÁRIO CLICA NA NOTIFICAÇÃO
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🔗 NOTIFICAÇÃO CLICADA: ${message.messageId}');
        _handleNotificationClick(message);
      }),
    );
  }

  void _setupBackgroundHandler() {
    print('🔄 CONFIGURANDO BACKGROUND HANDLER...');
    // Já configurado no main.dart como função top-level
  }

  // ✅ Handler específico para clique
  void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;
    final type = data['type'];

    print('📱 Navegando para notificação: $type');

    // Usar NavigationService para navegar
    final context = NavigationService.context;
    if (context != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NotificationsPage()),
        );
      });
    }

    _markNotificationAsClicked(data['notificationId']);
    _notificationStream.add(message);
  }

  // Handler estático para background
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    print("🔄 HANDLER BACKGROUND: ${message.messageId}");

    // ✅ INICIALIZAR FIREBASE NO BACKGROUND
    await Firebase.initializeApp();

    // ✅ CRIAR INSTÂNCIA E MOSTRAR NOTIFICAÇÃO
    final notificationService = NotificationService();
    await notificationService._initializeForBackground();
    await notificationService._showLocalNotification(message);
  }

  // ✅ NOVO: Inicialização específica para background
  Future<void> _initializeForBackground() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(settings);
    await _createNotificationChannel();
  }

  // ✅ MÉTODO CORRIGIDO: Mostrar notificação local
  Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'high_importance_channel', // ID do canal
            'Notificações Importantes', // Nome do canal
            channelDescription: 'Canal para notificações importantes',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList(const [0, 500, 200, 500]),
            channelShowBadge: true,
            enableLights: true,
            ledColor: const Color(0xFF2196F3),
            ledOnMs: 1000,
            ledOffMs: 500,
          );

      // Configuração iOS
      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        badgeNumber: 1,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Gerar ID único para a notificação
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _localNotifications.show(
        notificationId,
        message.notification?.title ?? 'Nova notificação',
        message.notification?.body ?? 'Você tem uma nova mensagem',
        details,
        payload: message.data['notificationId'] ?? message.messageId,
      );

      print('✅ Notificação local mostrada: $notificationId');

      // Atualizar badge
      await _updateBadgeCount();
    } catch (e) {
      print('❌ Erro ao mostrar notificação local: $e');
    }
  }

  // ✅ Atualizar badge count
  Future<void> _updateBadgeCount() async {
    try {
      final unreadCount = await getUnreadCount().first;

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iOSPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

        if (iOSPlugin != null) {
          // Tentar atualizar badge no iOS
          try {
            // await iOSPlugin.setBadgeCount(unreadCount);
            print('📱 iOS Badge count: $unreadCount');
          } catch (e) {
            print('⚠️ Método de badge não disponível: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Erro ao atualizar badge: $e');
    }
  }

  // ========== MÉTODOS PÚBLICOS ==========

  // Buscar usuário pelo ID usando sua model
  Future<Usuario?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('usuarios').doc(userId).get();
      if (doc.exists) {
        return Usuario.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ Erro ao buscar usuário $userId: $e');
      return null;
    }
  }

  // Stream de usuários usando sua model
  Stream<List<Usuario>> getUsersStream({bool excludeCurrentUser = true}) {
    final currentUserId = _auth.currentUser?.uid;

    return _firestore
        .collection('usuarios')
        .where('ativo', isEqualTo: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .where((doc) => !excludeCurrentUser || doc.id != currentUserId)
              .map((doc) => Usuario.fromMap(doc.data()))
              .toList(),
        );
  }

  // Enviar notificação para outro usuário
  Future<Map<String, dynamic>> sendNotification({
    required String toUserId,
    required String title,
    required String message,
    String type = 'general',
    String priority = 'medium',
    Map<String, dynamic>? data,
    Duration? expiresIn,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return {
          'success': false,
          'error': 'Usuário não autenticado',
          'message': 'É necessário estar logado para enviar notificações',
        };
      }

      final senderUser = await getUserById(currentUser.uid);
      if (senderUser == null) {
        return {
          'success': false,
          'error': 'Usuário remetente não encontrado',
          'message': 'Seu perfil não foi encontrado no sistema',
        };
      }

      final targetUser = await getUserById(toUserId);
      if (targetUser == null) {
        return {
          'success': false,
          'error': 'Usuário destino não encontrado',
          'message': 'O usuário destino não foi encontrado no sistema',
        };
      }

      if (!targetUser.ativo) {
        return {
          'success': false,
          'error': 'Usuário destino inativo',
          'message': 'O usuário destino está inativo no sistema',
        };
      }

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'createNotification',
      );

      final result = await callable.call(<String, dynamic>{
        'toUserId': toUserId,
        'title': title,
        'message': message,
        'type': type,
        'priority': priority,
        'additionalData': data,
        'expiresIn': expiresIn?.inSeconds,
        'senderData': {
          'id': senderUser.id,
          'nome': senderUser.nome,
          'email': senderUser.email,
          'fotoUrl': senderUser.fotoUrl,
          'isAdmin': senderUser.isAdmin,
        },
      });

      return {
        'success': true,
        'notificationId': result.data['notificationId'],
        'message': 'Notificação enviada com sucesso para ${targetUser.nome}',
      };
    } catch (e) {
      print('❌ Erro ao enviar notificação: $e');
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Erro ao enviar notificação',
      };
    }
  }

  // Enviar com retry automático
  Future<Map<String, dynamic>> sendNotificationWithRetry({
    required String toUserId,
    required String title,
    required String message,
    String type = 'general',
    String priority = 'medium',
    Map<String, dynamic>? data,
    Duration? expiresIn,
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🔄 Tentativa $attempt de enviar notificação');

        final result = await sendNotification(
          toUserId: toUserId,
          title: title,
          message: message,
          type: type,
          priority: priority,
          data: data,
          expiresIn: expiresIn,
        );

        if (result['success'] == true) {
          return result;
        }

        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt * 2));
        }
      } catch (e) {
        print('❌ Tentativa $attempt falhou: $e');
        if (attempt == maxRetries) {
          return {
            'success': false,
            'error': e.toString(),
            'message': 'Falha após $maxRetries tentativas',
          };
        }
      }
    }

    return {
      'success': false,
      'error': 'Todas as tentativas falharam',
      'message': 'Não foi possível enviar a notificação',
    };
  }

  // Marcar notificação como lida
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (_notificationCache.containsKey(notificationId)) {
        _notificationCache[notificationId]['read'] = true;
      }

      await _updateBadgeCount();
    } catch (e) {
      print('❌ Erro ao marcar como lida: $e');
      rethrow;
    }
  }

  // Marcar notificação como clicada
  Future<void> _markNotificationAsClicked(String? notificationId) async {
    if (notificationId == null) return;

    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'clicked': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Erro ao marcar como clicada: $e');
    }
  }

  // Marcar todas como lidas
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final notifications = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in notifications.docs) {
        batch.update(doc.reference, {
          'read': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      await _updateBadgeCount();

      print('✅ ${notifications.docs.length} notificações marcadas como lidas');
    } catch (e) {
      print('❌ Erro ao marcar todas como lidas: $e');
      rethrow;
    }
  }

  // Obter notificações do usuário atual
  Stream<QuerySnapshot> getUserNotifications() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<QuerySnapshot> getNotificationsPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    final userId = _auth.currentUser?.uid;
    print('🔍 Buscando notificações para usuário: $userId');

    if (userId == null) {
      print('❌ Usuário não logado');
      throw Exception('Usuário não logado');
    }

    var query = _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit);

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    final snapshot = await query.get();
    print('📊 Notificações no Firestore: ${snapshot.docs.length}');

    return snapshot;
  }

  // Obter número de notificações não lidas
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

  // Obter estatísticas de notificações
  Future<Map<String, int>> getNotificationStats() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return {};

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    final todayQuery = _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startOfDay));

    final weekQuery = _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('createdAt', isGreaterThan: Timestamp.fromDate(startOfWeek));

    final unreadQuery = _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('read', isEqualTo: false);

    final todaySnapshot = await todayQuery.get();
    final weekSnapshot = await weekQuery.get();
    final unreadSnapshot = await unreadQuery.get();
    final totalSnapshot = await _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .get();

    return {
      'today': todaySnapshot.docs.length,
      'thisWeek': weekSnapshot.docs.length,
      'unread': unreadSnapshot.docs.length,
      'total': totalSnapshot.docs.length,
    };
  }

  // Buscar notificações por tipo
  Stream<QuerySnapshot> getNotificationsByType(String type) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('notifications')
        .where('toUserId', isEqualTo: userId)
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Deletar notificação
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();

      _notificationCache.remove(notificationId);
    } catch (e) {
      print('❌ Erro ao deletar notificação: $e');
      rethrow;
    }
  }

  // Deletar notificações antigas
  Future<void> deleteOldNotifications({int days = 30}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final cutoffDate = DateTime.now().subtract(Duration(days: days));

    try {
      final oldNotifications = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .where('createdAt', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ ${oldNotifications.docs.length} notificações antigas deletadas');
    } catch (e) {
      print('❌ Erro ao deletar notificações antigas: $e');
    }
  }

  // Limpar todas as notificações
  Future<void> clearAllNotifications() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final allNotifications = await _firestore
          .collection('notifications')
          .where('toUserId', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in allNotifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      _notificationCache.clear();
      await _updateBadgeCount();

      print('✅ ${allNotifications.docs.length} notificações deletadas');
    } catch (e) {
      print('❌ Erro ao limpar todas as notificações: $e');
      rethrow;
    }
  }

  // Limpar badge
  Future<void> clearBadge() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iOSPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();

        if (iOSPlugin != null) {
          try {
            // await iOSPlugin.setBadgeCount(0);
            print('✅ Badge limpo (iOS)');
          } catch (e) {
            print('⚠️ Método de badge não disponível: $e');
          }
        }
      }
    } catch (e) {
      print('❌ Erro ao limpar badge: $e');
    }
  }

  // ✅ MÉTODO DE TESTE PARA NOTIFICAÇÕES LOCAIS
  Future<void> testLocalNotification() async {
    try {
      final androidDetails = AndroidNotificationDetails(
        'high_importance_channel',
        'Notificações Importantes',
        channelDescription: 'Canal para notificações importantes',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(const [0, 500, 200, 500]),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'Teste de Notificação',
        'Esta é uma notificação de teste do app!',
        details,
        payload: 'test_notification',
      );

      print('✅ Notificação de teste enviada com sucesso!');
    } catch (e) {
      print('❌ Erro ao enviar notificação de teste: $e');
    }
  }

  // Dispose para limpar recursos
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _notificationStream.close();
    _isInitialized = false;
    print('🔴 NotificationService disposed');
  }

  // ✅ ADICIONE ESTE MÉTODO PARA DIAGNÓSTICO
  Future<void> checkFCMConfiguration() async {
    print('\n🔍 DIAGNÓSTICO FCM');
    print('=' * 30);

    try {
      // Verificar token
      final token = await _firebaseMessaging.getToken();
      print('📱 Token FCM: ${token != null ? "✅" : "❌"}');
      if (token != null) {
        print('   - Token: ${token.substring(0, 20)}...');
      }

      // Verificar permissões
      final settings = await _firebaseMessaging.getNotificationSettings();
      print('🔔 Permissões:');
      print('   - Alert: ${settings.alert}');
      print('   - Badge: ${settings.badge}');
      print('   - Sound: ${settings.sound}');
      print('   - Authorization: ${settings.authorizationStatus}');

      // Verificar se está ouvindo
      print('👂 Listeners ativos: ${_subscriptions.length}');
    } catch (e) {
      print('❌ Erro no diagnóstico: $e');
    }
  }

  // ✅ ADICIONE ESTE MÉTODO PARA VERIFICAR O FLUXO COMPLETO
  Future<void> debugNotificationFlow(String targetUserId) async {
    print('\n🔍 DEBUG: FLUXO DE NOTIFICAÇÃO');
    print('=' * 40);

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('❌ Usuário não autenticado');
        return;
      }

      // 1. VERIFICAR TOKEN DO USUÁRIO ATUAL
      final myToken = await _firebaseMessaging.getToken();
      print('📱 MEU Token FCM: ${myToken?.substring(0, 20)}...');

      // 2. VERIFICAR TOKEN DO USUÁRIO ALVO
      final targetUserDoc = await _firestore
          .collection('usuarios')
          .doc(targetUserId)
          .get();
      final targetUserToken = targetUserDoc.data()?['fcmToken'];
      print('🎯 Token FCM do ALVO: ${targetUserToken != null ? "✅" : "❌"}');
      if (targetUserToken != null) {
        print('   - Token: ${targetUserToken.substring(0, 20)}...');
      }

      // 3. VERIFICAR SE O ALVO É DIFERENTE DE MIM
      final isSelf = targetUserId == currentUser.uid;
      print('👥 Enviando para outro usuário: ${!isSelf}');

      // 4. VERIFICAR LISTENERS
      print('👂 Meus listeners ativos: ${_subscriptions.length}');

      // 5. TESTAR NOTIFICAÇÃO
      if (!isSelf && targetUserToken != null) {
        print('🚀 TESTANDO ENVIO PARA OUTRO USUÁRIO...');

        final result = await sendNotification(
          toUserId: targetUserId,
          title: 'Debug Test',
          message: 'Esta é uma notificação de debug',
          data: {
            'debug': 'true',
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          },
        );

        print(
          '📤 Resultado do envio: ${result['success'] ? '✅' : '❌ ${result['error']}'}',
        );

        if (result['success'] == true) {
          print('💡 A notificação FOI ENVIADA para o FCM do usuário alvo');
          print('💡 O usuário alvo deve receber automaticamente via FCM');
        }
      } else if (isSelf) {
        print('ℹ️  Enviando para si mesmo - mostrando notificação local');
        await testLocalNotification();
      } else {
        print('❌ Não é possível testar - usuário alvo sem token FCM');
      }
    } catch (e) {
      print('❌ Erro no debug: $e');
    }
  }

  // ✅ ADICIONE ESTE MÉTODO DE DEBUG FCM
  void _setupFCMDebug() {
    print('🔍 INICIANDO DEBUG FCM...');

    // LISTENER PARA VER SE O FCM ESTÁ CHEGANDO
    _subscriptions.add(
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🎯 FCM RECEBIDO!');
        print('   - MessageId: ${message.messageId}');
        print('   - Title: ${message.notification?.title}');
        print('   - Body: ${message.notification?.body}');
        print('   - Data: ${message.data}');

        // Mostrar notificação local do FCM
        _showLocalNotification(message);
      }),
    );

    // LISTENER PARA BACKGROUND
    _subscriptions.add(
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        print('🔗 FCM CLICADO (background): ${message.messageId}');
      }),
    );
  }

  Future<void> testNotificationNow() async {
    print('🚀 TESTANDO NOTIFICAÇÃO LOCAL...');

    try {
      final AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'high_importance_channel',
            'Notificações Importantes',
            channelDescription: 'Canal para notificações importantes',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            vibrationPattern: Int64List.fromList(const [0, 500, 200, 500]),
            channelShowBadge: true,
            enableLights: true,
            ledColor: Colors.blue,
            ledOnMs: 1000,
            ledOffMs: 500,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        9999, // ID fixo para teste
        '🔥 TESTE DE NOTIFICAÇÃO',
        'Se esta notificação aparecer, o problema está no FCM!',
        details,
      );

      print('✅ NOTIFICAÇÃO LOCAL ENVIADA COM SUCESSO!');
    } catch (e) {
      print('❌ ERRO NA NOTIFICAÇÃO LOCAL: $e');
    }
  }
}
