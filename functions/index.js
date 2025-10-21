
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { setGlobalOptions } = require("firebase-functions/v2");

// Configuração global
setGlobalOptions({
  maxInstances: 10,
  timeoutSeconds: 540, // 9 minutos máximo
  memory: "512MiB",
});

const admin = require("firebase-admin");
admin.initializeApp();

// Constantes e configurações
const MAX_NOTIFICATIONS_PER_MINUTE = 10;
const NOTIFICATION_TTL_DAYS = 30;
const VALID_TYPES = ["message", "friend_request", "system", "like", "comment", "general"];
const VALID_PRIORITIES = ["low", "medium", "high"];

/**
 * Validação de dados de notificação
 */
function validateNotificationData(data, context) {
  const { toUserId, title, message, type, priority } = data;

  // Campos obrigatórios
  if (!toUserId || !title || !message) {
    throw new HttpsError(
      "invalid-argument",
      "Campos obrigatórios faltando: toUserId, title, message"
    );
  }

  // Validação de tipo
  if (type && !VALID_TYPES.includes(type)) {
    throw new HttpsError(
      "invalid-argument",
      `Tipo inválido. Use: ${VALID_TYPES.join(", ")}`
    );
  }

  // Validação de prioridade
  if (priority && !VALID_PRIORITIES.includes(priority)) {
    throw new HttpsError(
      "invalid-argument",
      `Prioridade inválida. Use: ${VALID_PRIORITIES.join(", ")}`
    );
  }

  // Prevenir auto-notificação
  //if (toUserId === context.auth.uid) {
  //  throw new HttpsError(
  //    "invalid-argument",
  //    "Não é possível enviar notificação para si mesmo"
  //  );
  // }

  return true;
}

/**
 * Verificar limite de rate limiting
 */
async function checkRateLimit(userId) {
  const oneMinuteAgo = new Date(Date.now() - 60000);

  const recentNotifications = await admin.firestore()
    .collection("notifications")
    .where("fromUserId", "==", userId)
    .where("createdAt", ">", oneMinuteAgo)
    .get();

  if (recentNotifications.size >= MAX_NOTIFICATIONS_PER_MINUTE) {
    throw new HttpsError(
      "resource-exhausted",
      `Limite de ${MAX_NOTIFICATIONS_PER_MINUTE} notificações por minuto excedido. Tente novamente mais tarde.`
    );
  }

  return true;
}

/**
 * Criar notificação - Função callable (ATUALIZADO PARA v2)
 */
/**
 * Criar notificação e ENVIAR FCM IMEDIATAMENTE - CORRIGIDA
 */
exports.createNotification = onCall(
  {
    enforceAppCheck: false,
    cors: true,
  },
  async (request) => {
    const { data, auth } = request;
    const startTime = Date.now();
    const functionName = "createNotification";

    if (!auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    try {
      console.log(`[${functionName}] Iniciando criação de notificação`, {
        userId: auth.uid,
        timestamp: new Date().toISOString(),
      });

      // Validações
      validateNotificationData(data, { auth });
      await checkRateLimit(auth.uid);

      const {
        toUserId,
        title,
        message,
        type = "general",
        priority = "medium",
        additionalData = {},
        expiresIn,
        senderData,
        platform = "web",
      } = data;

      // Verificar se usuário destino existe
      const userDoc = await admin.firestore()
        .collection("usuarios")
        .doc(toUserId)
        .get();

      if (!userDoc.exists) {
        throw new HttpsError("not-found", "Usuário destino não encontrado");
      }

      const userData = userDoc.data();

      if (userData.ativo === false) {
        throw new HttpsError("failed-precondition", "Usuário destino está inativo");
      }

      // Obter dados do remetente
      let fromUserData = senderData;
      if (!fromUserData) {
        const fromUserDoc = await admin.firestore()
          .collection("usuarios")
          .doc(auth.uid)
          .get();
        fromUserData = fromUserDoc.data() || {};
      }

      // Calcular data de expiração
      let expiresAt = null;
      if (expiresIn) {
        expiresAt = new Date(Date.now() + expiresIn * 1000);
      } else {
        expiresAt = new Date(Date.now() + NOTIFICATION_TTL_DAYS * 24 * 60 * 60 * 1000);
      }

      // ✅ 1. CRIAR NOTIFICAÇÃO NO FIRESTORE
      const notificationData = {
        fromUserId: auth.uid,
        fromUserName: fromUserData.nome || auth.token?.name || "Usuário",
        fromUserPhoto: fromUserData.fotoUrl || null,
        fromUserEmail: fromUserData.email || null,
        fromUserIsAdmin: fromUserData.isAdmin || false,
        toUserId: toUserId,
        title: title,
        message: message,
        type: type,
        priority: priority,
        platform: platform,
        read: false,
        clicked: false,
        expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        data: {
          ...additionalData,
          senderTipo: fromUserData.isAdmin ? "admin" : "usuario",
          senderPermissoes: fromUserData.perfil?.permissoes || [],
        },
      };

      const notificationRef = await admin.firestore()
        .collection("notifications")
        .add(notificationData);

      const notificationId = notificationRef.id;

      console.log(`[${functionName}] Notificação criada no Firestore`, {
        notificationId: notificationId,
      });

      // ✅ 2. ENVIAR NOTIFICAÇÃO FCM (CORRIGIDO - APENAS STRINGS NO DATA)
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.warn(`[${functionName}] Usuário ${toUserId} não tem FCM token`);

        await notificationRef.update({
          status: "no_token",
          sent: false,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return {
          success: true,
          notificationId: notificationId,
          message: "Notificação criada mas usuário não tem token FCM",
          fcmSent: false,
        };
      }

      // ✅ CORREÇÃO: CONVERTER TODOS OS VALORES DO DATA PARA STRING
      const stringifiedAdditionalData = {};
      if (additionalData) {
        Object.keys(additionalData).forEach(key => {
          const value = additionalData[key];
          // Converter para string qualquer valor que não seja string
          stringifiedAdditionalData[key] = typeof value === 'string' ? value : String(value);
        });
      }

      // ✅ PAYLOAD FCM CORRETO (APENAS STRINGS NO DATA)
      const payload = {
        token: fcmToken,
        notification: {
          title: title,
          body: message,
        },
        data: {
          // ✅ APENAS STRINGS - CRÍTICO!
          notificationId: notificationId,
          type: type,
          fromUserId: auth.uid,
          fromUserName: String(fromUserData.nome || "Usuário"),
          fromUserIsAdmin: String(fromUserData.isAdmin || false),
          priority: priority,
          //click_action: "FLUTTER_NOTIFICATION_CLICK",
          route: _getNotificationRoute(type, additionalData),
          timestamp: String(Date.now()),
          // ✅ Dados adicionais convertidos para string
          ...stringifiedAdditionalData,
        },
        webpush: {
          headers: {
            Urgency: priority === "high" ? "high" : "normal",
          },
          notification: {
            icon: '/icons/icon-192.png',
            badge: '/icons/icon-72.png',
            requireInteraction: true,
            actions: [
              {
                action: 'open',
                title: 'Abrir App'
              }
            ]
          },
          fcmOptions: {
            link: '/',
          }
        },
        android: {
          priority: priority === "high" ? "high" : "normal",
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: "default",
            },
          },
        },
      };

      console.log(`[${functionName}] Enviando FCM para web`, {
        token: fcmToken.substring(0, 20) + '...',
        platform: platform,
      });

      // ✅ ENVIAR VIA FCM
      const fcmResponse = await admin.messaging().send(payload);

      // ✅ ATUALIZAR NOTIFICAÇÃO
      await notificationRef.update({
        status: "sent",
        sent: true,
        fcmMessageId: fcmResponse,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`[${functionName}] Notificação FCM enviada com sucesso`, {
        notificationId: notificationId,
        fcmMessageId: fcmResponse,
        duration: Date.now() - startTime,
      });

      return {
        success: true,
        notificationId: notificationId,
        message: "Notificação criada e enviada com sucesso",
        fcmSent: true,
        fcmMessageId: fcmResponse,
      };

    } catch (error) {
      console.error(`[${functionName}] Erro ao criar/enviar notificação`, {
        error: error.message,
        userId: auth?.uid,
        duration: Date.now() - startTime,
        stack: error.stack,
      });

      throw new HttpsError("internal", `Erro ao criar notificação: ${error.message}`);
    }
  }
);


/**
 * Enviar notificação push quando uma notificação é criada (ATUALIZADO PARA v2)
 */
exports.sendPushNotification = onDocumentCreated(
  {
    document: "notifications/{notificationId}",
    memory: "512MiB",
    timeoutSeconds: 60,
  },
  async (event) => {
    const startTime = Date.now();
    const notificationId = event.params.notificationId;
    const functionName = "sendPushNotification";

    try {
      const snapshot = event.data;
      if (!snapshot) {
        console.warn(`[${functionName}] Snapshot não encontrado`);
        return;
      }

      const notification = snapshot.data();

      // Obter token FCM da coleção 'usuarios'
      const userDoc = await admin.firestore()
        .collection("usuarios")
        .doc(notification.toUserId)
        .get();

      if (!userDoc.exists) {
        console.warn(`[${functionName}] Usuário ${notification.toUserId} não encontrado`);
        return;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.warn(`[${functionName}] Usuário ${notification.toUserId} não tem FCM token`);
        return;
      }

      // Verificar se usuário está ativo
      if (userData.ativo === false) {
        console.warn(`[${functionName}] Usuário ${notification.toUserId} está inativo`);
        return;
      }

      // Preparar payload da notificação
      const payload = {
        notification: {
          title: notification.title,
          body: notification.message,
          sound: "default",
          badge: "1",
        },
        data: {
          notificationId: notificationId,
          type: notification.type,
          fromUserId: notification.fromUserId,
          fromUserName: notification.fromUserName,
          fromUserIsAdmin: notification.fromUserIsAdmin?.toString() || "false",
          priority: notification.priority,
          //click_action: "FLUTTER_NOTIFICATION_CLICK",
          route: _getNotificationRoute(notification.type, notification.data),
        },
        token: fcmToken,
        android: {
          priority: notification.priority === "high" ? "high" : "normal",
          ttl: 3600 * 1000, // 1 hora
        },
        apns: {
          payload: {
            aps: {
              badge: 1,
              sound: "default",
              category: notification.type,
            },
          },
          headers: {
            "apns-priority": notification.priority === "high" ? "10" : "5",
          },
        },
      };

      // Enviar notificação
      const response = await admin.messaging().send(payload);

      console.log(`[${functionName}] Notificação push enviada com sucesso`, {
        notificationId: notificationId,
        messageId: response,
        duration: Date.now() - startTime,
      });

      return null;
    } catch (error) {
      console.error(`[${functionName}] Erro ao enviar notificação push`, {
        notificationId: notificationId,
        error: error.message,
        duration: Date.now() - startTime,
        stack: error.stack,
      });

      return null;
    }
  }
);

/**
 * Helper para determinar a rota da notificação
 */
/**
 * Helper para determinar a rota da notificação (ATUALIZADO)
 */
function _getNotificationRoute(type, data) {
  switch (type) {
    case "message":
      return `/chat/${data.chatId || ""}`;
    case "friend_request":
      return "/friends/requests";
    case "like":
    case "comment":
      return `/post/${data.postId || ""}`;
    case "general":
      return "/notifications";
    default:
      return "/"; // ✅ Padrão para web
  }
}

/**
 * Enviar notificação em lote para múltiplos usuários (ATUALIZADO PARA v2)
 */
exports.sendBulkNotification = onCall(
  {
    enforceAppCheck: false,
    cors: true,
    memory: "1GiB",
  },
  async (request) => {
    const { data, auth } = request;

    if (!auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    const { userIds, title, message, type = "system", additionalData = {} } = data;

    if (!userIds || !Array.isArray(userIds) || userIds.length === 0) {
      throw new HttpsError("invalid-argument", "Lista de usuários inválida ou vazia");
    }

    if (userIds.length > 1000) {
      throw new HttpsError("invalid-argument", "Número máximo de usuários excedido (1000)");
    }

    try {
      const batch = admin.firestore().batch();
      const notificationsRef = admin.firestore().collection("notifications");
      const fromUserDoc = await admin.firestore()
        .collection("users")
        .doc(auth.uid)
        .get();

      const fromUserData = fromUserDoc.data() || {};
      const expiresAt = new Date(Date.now() + NOTIFICATION_TTL_DAYS * 24 * 60 * 60 * 1000);

      userIds.forEach((userId) => {
        const notificationRef = notificationsRef.doc();
        batch.set(notificationRef, {
          fromUserId: auth.uid,
          fromUserName: fromUserData.name || "Sistema",
          fromUserPhoto: fromUserData.photoURL || null,
          toUserId: userId,
          title,
          message,
          type,
          priority: "medium",
          read: false,
          clicked: false,
          expiresAt: admin.firestore.Timestamp.fromDate(expiresAt),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          data: additionalData,
        });
      });

      await batch.commit();

      console.log("Notificações em lote criadas", {
        count: userIds.length,
        fromUserId: auth.uid,
      });

      return {
        success: true,
        count: userIds.length,
        message: `${userIds.length} notificações criadas com sucesso`,
      };
    } catch (error) {
      console.error("Erro ao criar notificações em lote", {
        error: error.message,
        userId: auth.uid,
      });

      throw new HttpsError("internal", `Erro ao criar notificações em lote: ${error.message}`);
    }
  }
);

/**
 * Limpeza automática de notificações expiradas (ATUALIZADO PARA v2)
 */
exports.cleanExpiredNotifications = onSchedule(
  {
    schedule: "every 24 hours",
    timeZone: "America/Sao_Paulo",
    memory: "512MiB",
    timeoutSeconds: 540,
  },
  async (event) => {
    const startTime = Date.now();
    const functionName = "cleanExpiredNotifications";

    try {
      console.log(`[${functionName}] Iniciando limpeza de notificações expiradas`);

      const now = new Date();
      const expiredNotifications = await admin.firestore()
        .collection("notifications")
        .where("expiresAt", "<", now)
        .limit(500) // Limitar para evitar timeout
        .get();

      const batch = admin.firestore().batch();
      expiredNotifications.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      console.log(`[${functionName}] Limpeza concluída`, {
        deletedCount: expiredNotifications.size,
        duration: Date.now() - startTime,
      });

      return null;
    } catch (error) {
      console.error(`[${functionName}] Erro na limpeza`, {
        error: error.message,
        duration: Date.now() - startTime,
      });
      return null;
    }
  }
);

/**
 * Estatísticas de notificações (ATUALIZADO PARA v2)
 */
exports.getNotificationStats = onCall(
  {
    enforceAppCheck: false,
    cors: true,
  },
  async (request) => {
    const { auth } = request;

    if (!auth) {
      throw new HttpsError("unauthenticated", "Usuário não autenticado");
    }

    try {
      const userId = auth.uid;
      const now = new Date();
      const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
      const startOfWeek = new Date(now.setDate(now.getDate() - now.getDay()));
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

      const [
        totalNotifications,
        unreadNotifications,
        todayNotifications,
        weekNotifications,
        monthNotifications,
      ] = await Promise.all([
        // Total
        admin.firestore()
          .collection("notifications")
          .where("toUserId", "==", userId)
          .count()
          .get(),
        // Não lidas
        admin.firestore()
          .collection("notifications")
          .where("toUserId", "==", userId)
          .where("read", "==", false)
          .count()
          .get(),
        // Hoje
        admin.firestore()
          .collection("notifications")
          .where("toUserId", "==", userId)
          .where("createdAt", ">=", startOfDay)
          .count()
          .get(),
        // Esta semana
        admin.firestore()
          .collection("notifications")
          .where("toUserId", "==", userId)
          .where("createdAt", ">=", startOfWeek)
          .count()
          .get(),
        // Este mês
        admin.firestore()
          .collection("notifications")
          .where("toUserId", "==", userId)
          .where("createdAt", ">=", startOfMonth)
          .count()
          .get(),
      ]);

      return {
        success: true,
        stats: {
          total: totalNotifications.data().count,
          unread: unreadNotifications.data().count,
          today: todayNotifications.data().count,
          thisWeek: weekNotifications.data().count,
          thisMonth: monthNotifications.data().count,
        },
      };
    } catch (error) {
      console.error("Erro ao obter estatísticas", {
        error: error.message,
        userId: auth.uid,
      });

      throw new HttpsError("internal", `Erro ao obter estatísticas: ${error.message}`);
    }
  }
);