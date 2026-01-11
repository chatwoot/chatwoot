#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { build } = require('vite');

/**
 * Get the cache version for service worker
 * Priority: CHATWOOT_VERSION env var > git commit hash > timestamp
 */
function getCacheVersion() {
  if (process.env.CHATWOOT_VERSION) {
    return process.env.CHATWOOT_VERSION;
  }

  try {
    const gitHash = execSync('git rev-parse --short HEAD', {
      encoding: 'utf8',
    }).trim();
    return `git-${gitHash}`;
  } catch (error) {
    console.warn('Could not get git hash, using timestamp');
    return `v${Date.now()}`;
  }
}

/**
 * Generate asset manifest from Vite build output
 * Returns array of { url, revision } for JS/CSS files
 */
function generateAssetManifest() {
  const manifestPaths = [
    path.resolve(__dirname, '../public/packs/.vite/manifest.json'),
    path.resolve(__dirname, '../public/vite-dev/.vite/manifest.json'),
  ];

  let manifestPath = manifestPaths.find(p => fs.existsSync(p));

  if (!manifestPath) {
    console.warn(
      '⚠️  No Vite manifest found, skipping asset manifest generation'
    );
    return [];
  }

  console.log(`📋 Reading manifest from: ${manifestPath}`);

  const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
  const assets = [];
  const seen = new Set();

  for (const [, entry] of Object.entries(manifest)) {
    const file = entry.file;
    if (!file || seen.has(file)) continue;
    seen.add(file);

    // Only include JS and CSS files (not images, fonts, etc. - those are cached on demand)
    if (file.endsWith('.js') || file.endsWith('.css')) {
      assets.push({
        url: file,
        // revision is null because hash is in filename
        revision: null,
      });
    }
  }

  console.log(`📦 Found ${assets.length} JS/CSS assets to precache`);
  return assets;
}

/**
 * Build the service worker
 */
async function buildServiceWorker() {
  console.log('🔨 Building service worker...');

  const cacheVersion = getCacheVersion();
  const assetOrigin = process.env.ASSET_CDN_HOST || '';
  const isProduction = process.env.NODE_ENV === 'production';
  // In production assets are in /packs/, in development they're in /vite-dev/
  const assetPath = isProduction ? '/packs/' : '/vite-dev/';

  console.log(`📦 Cache version: ${cacheVersion}`);
  console.log(`🌐 Asset origin: ${assetOrigin || '(local)'}`);
  console.log(`📁 Asset path: ${assetPath}`);
  console.log(`🏭 Environment: ${isProduction ? 'production' : 'development'}`);

  // In development mode, just copy the push-handlers-only version
  if (!isProduction) {
    console.log(
      '⚠️  Development mode: Using push notifications only (no caching)'
    );

    const devServiceWorker = fs.readFileSync(
      path.resolve(
        __dirname,
        '../app/javascript/service-worker/push-handlers-only.js'
      ),
      'utf8'
    );

    fs.writeFileSync(
      path.resolve(__dirname, '../public/sw.js'),
      devServiceWorker
    );

    console.log('✅ Development service worker created at public/sw.js');
    return;
  }

  // Generate asset manifest for precaching
  const assetManifest = generateAssetManifest();

  // Production mode: Build with custom runtime
  try {
    console.log('📦 Building service worker runtime...');

    // Build the runtime bundle
    await build({
      configFile: false,
      css: {
        postcss: {
          plugins: [],
        },
      },
      build: {
        lib: {
          entry: path.resolve(
            __dirname,
            '../app/javascript/service-worker/sw-runtime.js'
          ),
          formats: ['iife'],
          name: 'ServiceWorkerRuntime',
          fileName: () => 'sw-runtime.js',
        },
        outDir: path.resolve(__dirname, '../tmp/sw-build'),
        emptyOutDir: true,
        minify: true,
        rollupOptions: {
          output: {
            inlineDynamicImports: true,
          },
        },
      },
      define: {
        __CACHE_VERSION__: JSON.stringify(cacheVersion),
        __ASSET_ORIGIN__: JSON.stringify(assetOrigin),
        __ASSET_PATH__: JSON.stringify(assetPath),
        __ASSET_MANIFEST__: JSON.stringify(assetManifest),
        'process.env.NODE_ENV': JSON.stringify('production'),
      },
      logLevel: 'warn',
    });

    console.log('✅ Service worker runtime built');

    // Read the built runtime
    const runtimeBundle = fs.readFileSync(
      path.resolve(__dirname, '../tmp/sw-build/sw-runtime.js'),
      'utf8'
    );

    // Read the push handlers template
    const pushHandlers = fs.readFileSync(
      path.resolve(
        __dirname,
        '../app/javascript/service-worker/push-handlers.js'
      ),
      'utf8'
    );

    // Replace version placeholder in push handlers
    const processedHandlers = pushHandlers.replace(
      /__CACHE_VERSION__/g,
      cacheVersion
    );

    // Combine them
    const finalServiceWorker = `/* Service Worker for Chatwoot - Generated at build time */
/* Cache version: ${cacheVersion} */
/* Generated: ${new Date().toISOString()} */
/* Precached assets: ${assetManifest.length} */

${runtimeBundle}

${processedHandlers}
`;

    // Write to public/sw.js
    fs.writeFileSync(
      path.resolve(__dirname, '../public/sw.js'),
      finalServiceWorker
    );

    console.log('✅ Service worker built successfully at public/sw.js');
    console.log(`   - ${assetManifest.length} assets in precache manifest`);
  } catch (error) {
    console.error('❌ Failed to build service worker:', error);
    process.exit(1);
  }
}

// Run the build
buildServiceWorker().catch(err => {
  console.error('❌ Unhandled error:', err);
  process.exit(1);
});
