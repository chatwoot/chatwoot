#!/usr/bin/env node
/* eslint-disable no-console */

const fs = require('fs');
const path = require('path');
const { build } = require('vite');

const ROOT_DIR = process.cwd();
const PATHS = {
  manifest: path.join(ROOT_DIR, 'public/vite/.vite/manifest.json'),
  swRuntime: path.join(__dirname, 'sw-runtime.js'),
  swRuntimeBuilt: path.join(ROOT_DIR, 'tmp/sw-build/sw-runtime.js'),
  pushHandlers: path.join(__dirname, 'push-handlers.js'),
  buildDir: path.join(ROOT_DIR, 'tmp/sw-build'),
  output: path.join(ROOT_DIR, 'public/sw.js'),
};

const buildSWContent = (runtimeBundle, pushHandlers, assetCount) => `
/* Service Worker for Chatwoot */
/* Generated: ${new Date().toISOString()} */
/* Precached assets: ${assetCount} */

${runtimeBundle}

${pushHandlers}
`;

function generateAssetManifest() {
  const manifestPath = fs.existsSync(PATHS.manifest) ? PATHS.manifest : null;

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

  Object.entries(manifest).forEach(([, entry]) => {
    const file = entry.file;
    if (file && !seen.has(file)) {
      seen.add(file);
      if (file.endsWith('.js') || file.endsWith('.css')) {
        assets.push({ url: file, revision: null });
      }
    }

    if (entry.css) {
      entry.css.forEach(cssFile => {
        if (!seen.has(cssFile)) {
          seen.add(cssFile);
          assets.push({ url: cssFile, revision: null });
        }
      });
    }

    if (entry.assets) {
      entry.assets.forEach(assetFile => {
        if (!seen.has(assetFile)) {
          seen.add(assetFile);
          assets.push({ url: assetFile, revision: null });
        }
      });
    }
  });

  console.log(`📦 Found ${assets.length} assets to precache`);
  return assets;
}

async function buildServiceWorker() {
  console.log('🔨 Building service worker...');

  let assetOrigin = process.env.ASSET_CDN_HOST || '';
  if (assetOrigin && !assetOrigin.startsWith('http')) {
    assetOrigin = `https://${assetOrigin}`;
  }

  const isProduction = process.env.NODE_ENV === 'production';
  const assetPath = '/vite/';

  console.log(`📁 Root dir: ${ROOT_DIR}`);
  console.log(`🌐 Asset origin: ${assetOrigin || '(local)'}`);
  console.log(`🏭 Environment: ${isProduction ? 'production' : 'development'}`);

  if (!isProduction) {
    console.log(
      '⚠️  Development mode: Using push notifications only (no caching)'
    );

    const devServiceWorker = fs.readFileSync(PATHS.pushHandlers, 'utf8');

    fs.writeFileSync(PATHS.output, devServiceWorker);

    console.log('✅ Development service worker created at public/sw.js');
    return;
  }

  const assetManifest = generateAssetManifest();

  try {
    console.log('📦 Building service worker runtime...');

    await build({
      configFile: false,
      css: {
        postcss: {
          plugins: [],
        },
      },
      build: {
        lib: {
          entry: PATHS.swRuntime,
          formats: ['iife'],
          name: 'ServiceWorkerRuntime',
          fileName: () => 'sw-runtime.js',
        },
        outDir: PATHS.buildDir,
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

    const runtimeBundle = fs.readFileSync(PATHS.swRuntimeBuilt, 'utf8');

    const pushHandlers = fs.readFileSync(PATHS.pushHandlers, 'utf8');

    const finalServiceWorker = buildSWContent(
      runtimeBundle,
      pushHandlers,
      assetManifest.length
    );

    fs.writeFileSync(PATHS.output, finalServiceWorker);

    console.log('✅ Service worker built successfully at public/sw.js');
    console.log(`   - ${assetManifest.length} assets in precache manifest`);
  } catch (error) {
    console.error('❌ Failed to build service worker:', error);
    process.exit(1);
  }
}

buildServiceWorker().catch(err => {
  console.error('❌ Unhandled error:', err);
  process.exit(1);
});
