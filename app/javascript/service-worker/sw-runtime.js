/* eslint-disable no-restricted-globals, no-use-before-define, no-undef */

// Build-time injected values (replaced by Vite define at build time)
const CACHE_VERSION = __CACHE_VERSION__;
const ASSET_ORIGIN = __ASSET_ORIGIN__;
const ASSET_PATH = __ASSET_PATH__;
const ASSET_MANIFEST = __ASSET_MANIFEST__;

const CACHE_NAME = `chatwoot-${CACHE_VERSION}`;

// Paths that should never be cached (API, auth, real-time, etc.)
const EXCLUDED_PATHS = [
  '/api/',
  '/auth/',
  '/rails/',
  '/cable',
  '/sidekiq',
  '/super_admin',
  '/swagger',
  '/webhooks/',
  '/widget',
  '/survey/',
  '/__vite',
  '/sw.js',
];

// =============================================================================
// Fetch Handler
// =============================================================================

self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);

  // Only handle GET requests from same origin or CDN
  if (request.method !== 'GET') return;
  const isOurRequest =
    url.origin === self.location.origin ||
    (ASSET_ORIGIN && url.origin === ASSET_ORIGIN);
  if (!isOurRequest) return;

  // Skip excluded paths
  if (EXCLUDED_PATHS.some(path => url.pathname.startsWith(path))) return;

  // Assets (JS/CSS/fonts) → cache-first
  const isAsset =
    url.pathname.startsWith('/vite-dev/') ||
    url.pathname.startsWith('/packs/') ||
    url.origin === ASSET_ORIGIN ||
    /\.(js|css|woff2?|ttf|otf|eot)$/i.test(url.pathname);

  if (isAsset) {
    event.respondWith(cacheFirst(request));
    return;
  }

  // Navigation to /app/* → network-first (cache HTML shell as fallback)
  if (request.mode === 'navigate' && url.pathname.startsWith('/app')) {
    event.respondWith(networkFirstWithShellCache(request));
  }
});

// =============================================================================
// Caching Strategies
// =============================================================================

async function cacheFirst(request) {
  const cache = await caches.open(CACHE_NAME);

  // Return cached version if available
  const cached = await cache.match(request);
  if (cached) return cached;

  // Otherwise fetch and cache
  try {
    const response = await fetch(request);
    if (response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  } catch (err) {
    // Network failed - return stale cache if available
    const stale = await cache.match(request);
    if (stale) return stale;
    throw err;
  }
}

async function networkFirstWithShellCache(request) {
  const cache = await caches.open(CACHE_NAME);

  try {
    const response = await fetch(request);

    // Cache the HTML shell for offline fallback
    if (response.ok) {
      const html = await response.clone().text();
      if (html.includes('data-sw-cache')) {
        cache.put(
          '/app',
          new Response(html, {
            headers: response.headers,
          })
        );
      }
    }

    return response;
  } catch (err) {
    // Network failed - return cached shell
    const cached = await cache.match('/app');
    if (cached) return cached;
    throw err;
  }
}

// =============================================================================
// Background Prefetch
// =============================================================================

async function prefetchAssets() {
  if (!ASSET_MANIFEST?.length) return;

  const cache = await caches.open(CACHE_NAME);
  const baseUrl = ASSET_ORIGIN || `${self.location.origin}${ASSET_PATH}`;

  // Prefetch in batches of 5 (await in loop is intentional for throttling)
  for (let i = 0; i < ASSET_MANIFEST.length; i += 5) {
    const batch = ASSET_MANIFEST.slice(i, i + 5);
    // eslint-disable-next-line no-await-in-loop
    await Promise.all(
      batch.map(async asset => {
        const url = `${baseUrl}${asset.url}`;
        if (await cache.match(url)) return; // Already cached

        try {
          const response = await fetch(url);
          if (response.ok) cache.put(url, response);
        } catch {
          // Ignore prefetch failures
        }
      })
    );
  }
}

// =============================================================================
// Lifecycle Events
// =============================================================================

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', event => {
  event.waitUntil(
    Promise.all([
      // Delete old caches
      caches
        .keys()
        .then(names =>
          Promise.all(
            names
              .filter(
                name => name.startsWith('chatwoot-') && name !== CACHE_NAME
              )
              .map(name => caches.delete(name))
          )
        ),
      // Take control of all clients
      self.clients.claim(),
    ])
  );
});

self.addEventListener('message', async event => {
  if (event.data?.type === 'PREFETCH_ASSETS') {
    await prefetchAssets();
    event.ports[0]?.postMessage({ type: 'PREFETCH_COMPLETE' });
  }
});
