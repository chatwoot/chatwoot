/* eslint-disable no-restricted-globals */
import { registerRoute } from 'workbox-routing';
import { CacheFirst } from 'workbox-strategies';
import { CacheableResponsePlugin } from 'workbox-cacheable-response';
import { ExpirationPlugin } from 'workbox-expiration';

// Cache version will be injected at build time
const CACHE_VERSION = '__CACHE_VERSION__';

// Asset origin will be injected at build time (CDN host or empty string)
const ASSET_ORIGIN = '__ASSET_ORIGIN__';

// Define cache names with versioning
const JS_CACHE = `js-cache-${CACHE_VERSION}`;
const CSS_CACHE = `css-cache-${CACHE_VERSION}`;
const FONT_CACHE = `font-cache-${CACHE_VERSION}`;

// Cache JavaScript bundles from /packs/ or CDN
registerRoute(
  ({ request, url }) => {
    const isScript = request.destination === 'script';
    const isFromPacks = url.pathname.startsWith('/packs/');
    const isFromCDN = ASSET_ORIGIN && url.origin === ASSET_ORIGIN;

    return isScript && (isFromPacks || isFromCDN);
  },
  new CacheFirst({
    cacheName: JS_CACHE,
    plugins: [
      new CacheableResponsePlugin({
        statuses: [0, 200], // 0 for opaque responses from CDN, 200 for same-origin
      }),
      new ExpirationPlugin({
        maxEntries: 100,
        maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
      }),
    ],
  })
);

// Cache CSS files from /packs/ or CDN
registerRoute(
  ({ request, url }) => {
    const isStyle = request.destination === 'style';
    const isFromPacks = url.pathname.startsWith('/packs/');
    const isFromCDN = ASSET_ORIGIN && url.origin === ASSET_ORIGIN;

    return isStyle && (isFromPacks || isFromCDN);
  },
  new CacheFirst({
    cacheName: CSS_CACHE,
    plugins: [
      new CacheableResponsePlugin({
        statuses: [0, 200],
      }),
      new ExpirationPlugin({
        maxEntries: 30,
        maxAgeSeconds: 30 * 24 * 60 * 60, // 30 days
      }),
    ],
  })
);

// Cache fonts (from anywhere)
registerRoute(
  ({ request, url }) => {
    const isFont = request.destination === 'font';
    const hasFontExtension = /\.(woff|woff2|ttf|otf|eot)$/i.test(url.pathname);

    return isFont || hasFontExtension;
  },
  new CacheFirst({
    cacheName: FONT_CACHE,
    plugins: [
      new CacheableResponsePlugin({
        statuses: [0, 200],
      }),
      new ExpirationPlugin({
        maxEntries: 30,
        maxAgeSeconds: 365 * 24 * 60 * 60, // 1 year
      }),
    ],
  })
);
