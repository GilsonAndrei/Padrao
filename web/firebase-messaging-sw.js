// web/firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

// ✅ CONFIGURAÇÃO DO FIREBASE NO SERVICE WORKER
firebase.initializeApp({
    apiKey: "AIzaSyAlgBYvyY2YfnpRilWC4AhBhHpVuGjhODo",
    authDomain: "padrao-210e0.firebaseapp.com",
    projectId: "padrao-210e0",
    storageBucket: "padrao-210e0.firebasestorage.app",
    messagingSenderId: "1046853830353",
    appId: "1:1046853830353:web:488da1cf583bb4e5e9a7f0"
});

const messaging = firebase.messaging();

// ✅ BACKGROUND MESSAGE HANDLER (CRÍTICO)
messaging.onBackgroundMessage((payload) => {
    console.log('🌐 [SW] Notificação em background recebida:', payload);

    const notificationTitle = payload.notification?.title || 'Nova notificação';
    const notificationOptions = {
        body: payload.notification?.body || '',
        icon: '/icons/icon-192.png', // Use ícone local ou remoto
        badge: '/icons/icon-72.png',
        data: payload.data || {},
        tag: 'background-notification',
        requireInteraction: true
    };

    // Mostrar notificação
    return self.registration.showNotification(notificationTitle, notificationOptions);
});

// ✅ NOTIFICATION CLICK HANDLER
self.addEventListener('notificationclick', (event) => {
    console.log('🌐 [SW] Notificação clicada:', event.notification);

    event.notification.close();

    const notificationData = event.notification.data || {};

    // Focar na janela existente ou abrir nova
    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true })
            .then((clientList) => {
                // Tentar focar em janela existente
                for (const client of clientList) {
                    if (client.url.includes(self.location.origin) && 'focus' in client) {
                        return client.focus();
                    }
                }

                // Abrir nova janela se não existir
                if (clients.openWindow) {
                    const targetUrl = notificationData.route || '/';
                    return clients.openWindow(targetUrl);
                }
            })
    );
});