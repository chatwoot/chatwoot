import path from 'path';
import yaml from '@rollup/plugin-yaml';
import vue from '@vitejs/plugin-vue';
import { defineConfig, type PluginOption } from 'vite';
import { visualizer } from 'rollup-plugin-visualizer';
import { aliases, vueOptions } from './vite.shared';

export default defineConfig({
  plugins: [
    vue(vueOptions),
    yaml(),
    visualizer({
      filename: path.resolve(__dirname, 'tmp/bundle-analysis/widget.html'),
      title: 'Chatwoot widget bundle analysis',
      template: 'treemap',
      gzipSize: true,
      brotliSize: true,
      projectRoot: __dirname,
    }) as PluginOption,
  ],
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler',
      },
    },
  },
  publicDir: false,
  build: {
    outDir: 'tmp/bundle-analysis/widget',
    emptyOutDir: true,
    copyPublicDir: false,
    rollupOptions: {
      input: path.resolve(__dirname, './app/javascript/entrypoints/widget.js'),
    },
  },
  resolve: { alias: aliases },
});
