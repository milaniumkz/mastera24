/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDCvy3xSd2NZldRVZjHKK9SOuCeRykpWN4',
  appId: '1:311694726:web:b32ad5282d9abe3cf40807',
  messagingSenderId: '311694726',
  projectId: 'mastera24-b48e2',
  authDomain: 'mastera24-b48e2.firebaseapp.com',
  storageBucket: 'mastera24-b48e2.firebasestorage.app',
  measurementId: 'G-WENWZ94BQD',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  const data = payload.data || {};
  const title = notification.title || 'MASTERA 24';
  const options = {
    body: notification.body || 'У вас новое уведомление.',
    data,
  };

  self.registration.showNotification(title, options);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const targetUrl = '/';
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((items) => {
      for (const client of items) {
        if (client.url.startsWith(self.location.origin)) {
          client.focus();
          return client.postMessage({
            type: 'notification-click',
            data: event.notification.data || {},
          });
        }
      }
      return clients.openWindow(targetUrl);
    }),
  );
});
