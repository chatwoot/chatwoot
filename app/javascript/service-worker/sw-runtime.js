/* eslint-disable no-restricted-globals, no-use-before-define, no-undef */

// Build-time injected values (replaced by Vite define at build time)
const ASSET_ORIGIN = __ASSET_ORIGIN__;
const ASSET_PATH = __ASSET_PATH__;
const ASSET_MANIFEST = __ASSET_MANIFEST__;

// Stable cache name - Vite includes content hashes in filenames,
// so unchanged files keep the same URL and don't need refetching
const CACHE_NAME = 'chatwoot-assets-v1';

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
    url.pathname.startsWith('/vite/') ||
    url.origin === ASSET_ORIGIN ||
    /\.(js|css|woff2?|ttf|otf|eot)$/i.test(url.pathname);

  if (isAsset) {
    event.respondWith(cacheFirst(request));
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

// =============================================================================
// Background Prefetch
// =============================================================================

async function prefetchAssets() {
  if (!ASSET_MANIFEST?.length) return;

  const cache = await caches.open(CACHE_NAME);
  // Build base URL: CDN origin + asset path, or local origin + asset path
  const baseUrl = ASSET_ORIGIN
    ? `${ASSET_ORIGIN}${ASSET_PATH}`
    : `${self.location.origin}${ASSET_PATH}`;

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
    Promise.all([cleanupStaleAssets(), prefetchAssets(), self.clients.claim()])
  );
});

/**
 * Remove cached assets that aren't in the current manifest.
 * This keeps unchanged files (same content hash) while removing old versions.
 */
async function cleanupStaleAssets() {
  if (!ASSET_MANIFEST?.length) return;

  const cache = await caches.open(CACHE_NAME);
  const cachedRequests = await cache.keys();
  // Build base URL: CDN origin + asset path, or local origin + asset path
  const baseUrl = ASSET_ORIGIN
    ? `${ASSET_ORIGIN}${ASSET_PATH}`
    : `${self.location.origin}${ASSET_PATH}`;

  // Build set of valid asset URLs from current manifest
  const validUrls = new Set(
    ASSET_MANIFEST.map(asset => `${baseUrl}${asset.url}`)
  );

  // Delete cached entries that are assets but not in current manifest
  const deletions = cachedRequests
    .filter(request => {
      const url = new URL(request.url);
      const isAssetPath =
        url.pathname.startsWith('/vite/assets/') ||
        url.pathname.startsWith('/vite-dev/assets/');
      // Only clean up asset files
      return isAssetPath && !validUrls.has(request.url);
    })
    .map(request => cache.delete(request));

  await Promise.all(deletions);
}
