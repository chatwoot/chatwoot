#!/usr/bin/env node
/* eslint-disable no-console, no-restricted-syntax, no-continue */

const fs = require('fs');
const path = require('path');
const { build } = require('vite');

/**
 * Generate asset manifest from Vite build output
 * Returns array of { url, revision } for JS/CSS files
 */
function generateAssetManifest() {
  // vite-plugin-ruby outputs to 'vite' in production, 'vite-dev' in development
  const manifestPaths = [
    path.resolve(__dirname, '../../../public/vite/.vite/manifest.json'),
    path.resolve(__dirname, '../../../public/vite-dev/.vite/manifest.json'),
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
    // Add the main file (JS or CSS)
    const file = entry.file;
    if (file && !seen.has(file)) {
      seen.add(file);
      if (file.endsWith('.js') || file.endsWith('.css')) {
        assets.push({ url: file, revision: null });
      }
    }

    // Add CSS files from the css array (CSS imported by JS modules)
    if (entry.css) {
      for (const cssFile of entry.css) {
        if (!seen.has(cssFile)) {
          seen.add(cssFile);
          assets.push({ url: cssFile, revision: null });
        }
      }
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

  // Ensure CDN host has protocol prefix for absolute URLs
  let assetOrigin = process.env.ASSET_CDN_HOST || '';
  if (assetOrigin && !assetOrigin.startsWith('http')) {
    assetOrigin = `https://${assetOrigin}`;
  }
  const isProduction = process.env.NODE_ENV === 'production';
  // vite-plugin-ruby serves from /vite/ in production, /vite-dev/ in development
  const assetPath = isProduction ? '/vite/' : '/vite-dev/';

  console.log(`🌐 Asset origin: ${assetOrigin || '(local)'}`);
  console.log(`📁 Asset path: ${assetPath}`);
  console.log(`🏭 Environment: ${isProduction ? 'production' : 'development'}`);

  // In development mode, just use push handlers (no caching)
  if (!isProduction) {
    console.log(
      '⚠️  Development mode: Using push notifications only (no caching)'
    );

    const devServiceWorker = fs.readFileSync(
      path.resolve(__dirname, 'push-handlers.js'),
      'utf8'
    );

    fs.writeFileSync(
      path.resolve(__dirname, '../../../public/sw.js'),
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
          entry: path.resolve(__dirname, 'sw-runtime.js'),
          formats: ['iife'],
          name: 'ServiceWorkerRuntime',
          fileName: () => 'sw-runtime.js',
        },
        outDir: path.resolve(__dirname, '../../../tmp/sw-build'),
        emptyOutDir: true,
        minify: true,
        rollupOptions: {
          output: {
            inlineDynamicImports: true,
          },
        },
      },
      define: {
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
      path.resolve(__dirname, '../../../tmp/sw-build/sw-runtime.js'),
      'utf8'
    );

    // Read the push handlers
    const pushHandlers = fs.readFileSync(
      path.resolve(__dirname, 'push-handlers.js'),
      'utf8'
    );

    // Combine them
    const finalServiceWorker = `/* Service Worker for Chatwoot - Generated at build time */
/* Generated: ${new Date().toISOString()} */
/* Precached assets: ${assetManifest.length} */

${runtimeBundle}

${pushHandlers}
`;

    // Write to public/sw.js
    fs.writeFileSync(
      path.resolve(__dirname, '../../../public/sw.js'),
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
