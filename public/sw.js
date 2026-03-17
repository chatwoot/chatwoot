/* eslint-disable no-restricted-globals, no-console */
/* globals clients */
const RECENT_PUSH_TTL = 10000;
const DEFAULT_VIBRATE_PATTERN = [300, 150, 300, 150, 450];
const recentPushes = new Map();

const notificationVibratePattern = notification => {
  if (Array.isArray(notification.vibrate) && notification.vibrate.length > 0) {
    return notification.vibrate;
  }

  return DEFAULT_VIBRATE_PATTERN;
};

const buildNotificationKey = notification => {
  return [notification.tag, notification.title, notification.body, notification.url]
    .filter(Boolean)
    .join('::');
};

const isRecentDuplicate = key => {
  if (!key) {
    return false;
  }

  const timestamp = recentPushes.get(key);
  if (!timestamp) {
    return false;
  }

  return Date.now() - timestamp < RECENT_PUSH_TTL;
};

const rememberNotification = key => {
  if (!key) {
    return;
  }

  const now = Date.now();
  recentPushes.set(key, now);

  recentPushes.forEach((timestamp, storedKey) => {
    if (now - timestamp >= RECENT_PUSH_TTL) {
      recentPushes.delete(storedKey);
    }
  });
};

self.addEventListener('push', event => {
  const notification = event.data && event.data.json();
  if (!notification) return;

  const notificationKey = buildNotificationKey(notification);

  const options = {
    body: notification.body || '',
    tag: notification.tag,
    icon: '/android-icon-192x192.png',
    badge: '/favicon-96x96.png',
    data: {
      url: notification.url,
    },
    vibrate: notificationVibratePattern(notification),
    renotify: false,
  };

  event.waitUntil((async () => {
    if (isRecentDuplicate(notificationKey)) {
      return;
    }

    if (notification.tag) {
      const existingNotifications = await self.registration.getNotifications({
        tag: notification.tag,
      });

      if (existingNotifications.length > 0) {
        rememberNotification(notificationKey);
        return;
      }
    }

    rememberNotification(notificationKey);
    await self.registration.showNotification(notification.title, options);
  })());
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
