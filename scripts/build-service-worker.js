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
 * Build the service worker
 */
async function buildServiceWorker() {
  console.log('🔨 Building service worker...');

  const cacheVersion = getCacheVersion();
  const assetOrigin = process.env.ASSET_CDN_HOST || '';
  const isProduction = process.env.NODE_ENV === 'production';

  console.log(`📦 Cache version: ${cacheVersion}`);
  console.log(`🌐 Asset origin: ${assetOrigin || '(local)'}`);
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

  // Production mode: Build with Workbox runtime
  try {
    console.log('📦 Building Workbox runtime bundle...');

    // Build the Workbox runtime bundle
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
          name: 'WorkboxRuntime',
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
        'process.env.NODE_ENV': JSON.stringify('production'),
      },
      logLevel: 'warn',
    });

    console.log('✅ Workbox runtime bundle built');

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

${runtimeBundle}

${processedHandlers}
`;

    // Write to public/sw.js
    fs.writeFileSync(
      path.resolve(__dirname, '../public/sw.js'),
      finalServiceWorker
    );

    console.log('✅ Service worker built successfully at public/sw.js');
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
