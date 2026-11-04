/*
 * SDK library build.
 *
 * vite-plugin-ruby pulls every entrypoint as input, but the SDK needs to ship
 * as a single IIFE file (`inlineDynamicImports: true`), which is incompatible
 * with multiple entrypoints. So the SDK gets its own pipeline:
 *
 *   vite build --config vite.lib.config.ts  → public/packs/js/sdk.js
 *
 * The `assets:precompile` rake task runs this alongside the main app build.
 */
import { brotliCompressSync, constants, gzipSync } from 'node:zlib';
import { defineConfig, type Plugin } from 'vite';
import path from 'path';
import { aliases } from './vite.shared';

const compressedSdkPlugin = {
  name: 'compress-sdk',
  generateBundle(_options, bundle) {
    const sdkBundle = bundle['js/sdk.js'];

    if (sdkBundle?.type !== 'chunk') {
      this.error('SDK bundle was not generated');
    }

    this.emitFile({
      type: 'asset',
      fileName: 'js/sdk.js.br',
      source: brotliCompressSync(sdkBundle.code, {
        params: {
          [constants.BROTLI_PARAM_QUALITY]: constants.BROTLI_MAX_QUALITY,
        },
      }),
    });

    this.emitFile({
      type: 'asset',
      fileName: 'js/sdk.js.gz',
      source: gzipSync(sdkBundle.code, {
        level: constants.Z_BEST_COMPRESSION,
      }),
    });
  },
} satisfies Plugin;

export default defineConfig({
  plugins: [compressedSdkPlugin],
  build: {
    rollupOptions: {
      output: {
        dir: 'public/packs',
        entryFileNames: chunkInfo =>
          chunkInfo.name === 'sdk' ? 'js/sdk.js' : '[name].js',
        inlineDynamicImports: true,
      },
    },
    lib: {
      entry: path.resolve(__dirname, './app/javascript/entrypoints/sdk.js'),
      formats: ['iife'],
      name: 'sdk',
    },
  },
  resolve: { alias: aliases },
});
