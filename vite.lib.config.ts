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
import { defineConfig } from 'vite';
import path from 'path';
import { aliases } from './vite.shared';

export default defineConfig({
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
