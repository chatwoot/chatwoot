/* eslint-disable no-restricted-globals, no-console */
/* globals clients */
const CACHE_NAME = 'vite-assets-cache-v1'; // Bump this to invalidate old caches
const CACHE_TTL = 7 * 24 * 60 * 60 * 1000; // 7 days in milliseconds
const CACHE_HEADER_NAME = 'x-woot-sw-cache-time';

async function addCacheTime(response) {
  const headers = new Headers(response.headers);
  headers.set(CACHE_HEADER_NAME, Date.now().toString());
  const body = await response.blob();
  return new Response(body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function isFresh(response) {
  const cachedTime = response.headers.get(CACHE_HEADER_NAME);
  if (!cachedTime) return false;
  return Date.now() - Number(cachedTime) < CACHE_TTL;
}

async function handleAssetRequest(request) {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);

  if (cached && isFresh(cached)) {
    return cached;
  }

  try {
    const response = await fetch(request);
    if (response.ok) {
      const responseToCache = await addCacheTime(response);
      // We naively cache everything - the browser will purge when needed
      cache.put(request, responseToCache.clone());
      return responseToCache;
    }
    return cached || response;
  } catch {
    return cached || new Response('', { status: 504, statusText: 'Gateway Timeout' });
  }
}

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);

  if (url.pathname.startsWith('/vite/assets/')) {
    event.respondWith(handleAssetRequest(event.request));
  }
});

// Clean up old caches on activate
// To trigger a cleanup we can simply change the `CACHE_NAME`
self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys =>
      Promise.all(
        keys
          .filter(key => key !== CACHE_NAME)
          .map(key => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener('push', event => {
  if (!event.data) {
    console.warn('Service Worker: Push event received without data');
    return;
  }

  try {
    const notification = event.data.json();

    if (!notification.title) {
      console.warn('Service Worker: Push notification missing title');
      return;
    }

    event.waitUntil(
      self.registration.showNotification(notification.title, {
        tag: notification.tag || 'default',
        body: notification.body || '',
        icon: notification.icon || '/favicon.ico',
        data: {
          url: notification.url || '/',
        },
      })
    );
  } catch (err) {
    console.error('Service Worker: Error parsing push notification', err);
  }
});

self.addEventListener('notificationclick', event => {
  const notification = event.notification;
  notification.close();

  const targetUrl = notification.data?.url || '/';

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true })
      .then(windowClients => {
        const matchingClient = windowClients.find(
          client => client.url === targetUrl
        );

        if (matchingClient) {
          return matchingClient.focus();
        }

        if (clients.openWindow) {
          return clients.openWindow(targetUrl);
        }
      })
      .catch(err => {
        console.error('Service Worker: Error handling notification click', err);
      })
  );
});
