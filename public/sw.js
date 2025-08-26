/* eslint-disable no-restricted-globals, no-console */
/* globals clients */
self.addEventListener('push', event => {
  let notification = event.data && event.data.json();

  event.waitUntil(
    // Check if any client windows are currently visible/focused
    clients
      .matchAll({
        type: 'window',
        includeUncontrolled: true,
      })
      .then(clients => {
        // Check if any of the clients are currently focused
        const isAppInForeground = clients.some(client => client.focused);

        // Only show notification if app is not in foreground
        if (!isAppInForeground) {
          return self.registration.showNotification(notification.title, {
            tag: notification.tag,
            body: notification.body,
            icon: notification.icon,
            badge: notification.badge,
            data: {
              url: notification.url,
            },
          });
        }

        // If app is in foreground, don't show notification
        // The app will handle it via ActionCable/in-app notifications
        return Promise.resolve();
      })
  );
});

self.addEventListener('notificationclick', event => {
  let notification = event.notification;

  event.waitUntil(
    clients.matchAll({ type: 'window' }).then(windowClients => {
      let matchingWindowClients = windowClients.filter(
        client => client.url === notification.data.url
      );

      if (matchingWindowClients.length) {
        let firstWindow = matchingWindowClients[0];
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
