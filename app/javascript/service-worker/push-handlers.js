/* eslint-disable no-restricted-globals */
/* globals clients */

// Push notification handler
self.addEventListener('push', event => {
  const notification = event.data && event.data.json();

  if (!notification) return;

  event.waitUntil(
    self.registration.showNotification(notification.title, {
      tag: notification.tag,
      data: {
        url: notification.url,
      },
    })
  );
});

// Notification click handler
self.addEventListener('notificationclick', event => {
  const notification = event.notification;
  notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(windowClients => {
      const matchingWindowClients = windowClients.filter(
        client => client.url === notification.data.url
      );

      if (matchingWindowClients.length) {
        const firstWindow = matchingWindowClients[0];
        if (firstWindow && 'focus' in firstWindow) {
          firstWindow.focus();
          return;
        }
      }
      if (clients.openWindow) {
        clients.openWindow(notification.data.url);
      }
    })
  );
});
