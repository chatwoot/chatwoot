import path from 'path';
import { defineConfig, type PluginOption } from 'vite';
import { visualizer } from 'rollup-plugin-visualizer';
import { aliases } from './vite.shared';

export default defineConfig({
  plugins: [
    visualizer({
      filename: path.resolve(__dirname, 'tmp/bundle-analysis/sdk.html'),
      title: 'Chatwoot SDK bundle analysis',
      template: 'treemap',
      gzipSize: true,
      brotliSize: true,
      projectRoot: __dirname,
    }) as PluginOption,
  ],
  build: {
    outDir: 'tmp/bundle-analysis/sdk',
    emptyOutDir: true,
    copyPublicDir: false,
    rollupOptions: {
      output: {
        entryFileNames: 'sdk.js',
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
