/* eslint-disable no-restricted-globals, no-use-before-define, no-undef */

// Build-time injected values (replaced by Vite define at build time)
const ASSET_ORIGIN = __ASSET_ORIGIN__;
const ASSET_PATH = __ASSET_PATH__;
const ASSET_MANIFEST = __ASSET_MANIFEST__;

const CACHE_NAME = 'chatwoot-assets-v1';

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

const BATCH_SIZE = 5;

const buildAssetListChunks = (arr, size) => {
  const result = [];
  for (let i = 0; i < arr.length; i += size) {
    result.push(arr.slice(i, i + size));
  }
  return result;
};

const prefetchBatch = async (cache, baseUrl, assets) => {
  const fetchAndCacheAsset = async asset => {
    const url = `${baseUrl}${asset.url}`;
    if (await cache.match(url)) {
      return;
    }
    try {
      const response = await fetch(url);
      if (response.ok) {
        cache.put(url, response);
      }
    } catch {
      // Ignore prefetch failures
    }
  };

  await Promise.all(assets.map(fetchAndCacheAsset));
};

const cacheFirst = async request => {
  const cache = await caches.open(CACHE_NAME);
  const cached = await cache.match(request);
  if (cached) return cached;

  try {
    const response = await fetch(request);
    if (response.ok) {
      cache.put(request, response.clone());
    }
    return response;
  } catch (err) {
    const stale = await cache.match(request);
    if (stale) return stale;
    throw err;
  }
};

const prefetchAssets = async () => {
  if (!ASSET_MANIFEST?.length) return;

  const cache = await caches.open(CACHE_NAME);
  const baseUrl = ASSET_ORIGIN
    ? `${ASSET_ORIGIN}${ASSET_PATH}`
    : `${self.location.origin}${ASSET_PATH}`;

  const batches = buildAssetListChunks(ASSET_MANIFEST, BATCH_SIZE);
  await batches.reduce(
    (promise, batch) =>
      promise.then(() => prefetchBatch(cache, baseUrl, batch)),
    Promise.resolve()
  );
};
const cleanupStaleAssets = async () => {
  if (!ASSET_MANIFEST?.length) return;

  const cache = await caches.open(CACHE_NAME);
  const cachedRequests = await cache.keys();

  const baseUrl = ASSET_ORIGIN
    ? `${ASSET_ORIGIN}${ASSET_PATH}`
    : `${self.location.origin}${ASSET_PATH}`;

  const validUrls = new Set(
    ASSET_MANIFEST.map(asset => `${baseUrl}${asset.url}`)
  );

  const deletions = cachedRequests
    .filter(request => {
      const url = new URL(request.url);
      const isAssetPath = url.pathname.startsWith('/vite/assets/');
      return isAssetPath && !validUrls.has(request.url);
    })
    .map(request => cache.delete(request));

  await Promise.all(deletions);
};

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', event => {
  event.waitUntil(
    Promise.all([cleanupStaleAssets(), prefetchAssets(), self.clients.claim()])
  );
});

self.addEventListener('fetch', event => {
  const { request } = event;
  const url = new URL(request.url);

  if (EXCLUDED_PATHS.some(path => url.pathname.startsWith(path))) return;

  if (request.method !== 'GET') return;

  const isAChatwootRequest =
    url.origin === self.location.origin ||
    (ASSET_ORIGIN && url.origin === ASSET_ORIGIN);

  if (!isAChatwootRequest) return;

  const isAnAsset =
    url.pathname.startsWith('/vite/') ||
    url.origin === ASSET_ORIGIN ||
    /\.(js|css|woff2?|ttf|otf|eot|svg|png)$/i.test(url.pathname);

  if (isAnAsset) {
    event.respondWith(cacheFirst(request));
  }
});
