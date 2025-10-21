importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js');

console.log('🌐 [SW] Service Worker carregado');

// 🔧 Inicialização
firebase.initializeApp({
    apiKey: "AIzaSyAlgBYvyY2YfnpRilWC4AhBhHpVuGjhODo",
    authDomain: "padrao-210e0.firebaseapp.com",
    projectId: "padrao-210e0",
    storageBucket: "padrao-210e0.firebasestorage.app",
    messagingSenderId: "1046853830353",
    appId: "1:1046853830353:web:488da1cf583bb4e5e9a7f0"
});

const messaging = firebase.messaging();

// ✅ Recebe notificações em background
messaging.onBackgroundMessage((payload) => {
    console.log('🌐 [SW] Notificação recebida (background):', payload);

    const notificationTitle = payload.notification?.title || 'Nova notificação';
    const notificationOptions = {
        body: payload.notification?.body || 'Você recebeu uma nova mensagem.',
        icon: '/icons/icon-192.png',
        badge: '/icons/icon-72.png',
        data: {
            click_action: payload.fcmOptions?.link || '/',
            payloadData: payload.data || {}
        },
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});

// ✅ Captura clique na notificação
self.addEventListener('notificationclick', (event) => {
    console.log('🌐 [SW] Notificação clicada');
    event.notification.close();

    const targetUrl = event.notification.data?.click_action || '/';

    event.waitUntil(
        clients.matchAll({ type: 'window', includeUncontrolled: true }).then(clientList => {
            // Se já tem aba aberta do app → foca nela
            for (const client of clientList) {
                if (client.url.includes(self.location.origin) && 'focus' in client) {
                    console.log('🌐 [SW] Focando aba existente');
                    client.focus();
                    client.postMessage({
                        type: 'NOTIFICATION_CLICK',
                        data: event.notification.data?.payloadData || {}
                    });
                    return;
                }
            }
            // Caso contrário → abre na mesma aba
            console.log('🌐 [SW] Abrindo nova aba para:', targetUrl);
            return clients.openWindow(targetUrl);
        })
    );
});

self.addEventListener('install', (event) => {
    console.log('🌐 [SW] Instalado');
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    console.log('🌐 [SW] Ativado');
    event.waitUntil(self.clients.claim());
});
