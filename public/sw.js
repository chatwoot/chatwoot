/* eslint-disable no-restricted-globals, no-console */
/* globals clients */
self.addEventListener('push', event => {
  const notification = event.data && event.data.json();
  if (!notification) return;

  const options = {
    body: notification.body || '',
    tag: notification.tag,
    icon: '/android-icon-192x192.png',
    badge: '/favicon-96x96.png',
    data: {
      url: notification.url,
    },
    vibrate: [200, 100, 200],
    renotify: true,
  };

  event.waitUntil(
    self.registration.showNotification(notification.title, options)
  );
});

self.addEventListener('notificationclick', event => {
  const notification = event.notification;
  notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(windowClients => {
      // Try to focus an existing window with the same URL
      const matchingClient = windowClients.find(
        client => client.url === notification.data.url
      );

      if (matchingClient && 'focus' in matchingClient) {
        return matchingClient.focus();
      }

      // Try to focus any existing window and navigate it
      if (windowClients.length > 0) {
        const client = windowClients[0];
        if ('focus' in client) {
          client.focus();
          if ('navigate' in client) {
            return client.navigate(notification.data.url);
          }
        }
      }

      // Open a new window as last resort
      if (clients.openWindow) {
        return clients.openWindow(notification.data.url);
      }

      return null;
    })
  );
});
