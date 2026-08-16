import { defineConfig } from 'vite';
import ruby from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import { aliases, vueOptions } from './vite.shared';
import yaml from '@rollup/plugin-yaml';

export default defineConfig({
  plugins: [ruby(), vue(vueOptions), yaml()],
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler',
      },
    },
  },
  resolve: { alias: aliases },
  server: {
    // Bind to all interfaces so the rails container can reach the dev server
    // at the `vite` service host (resolves to its IPv4, not localhost).
    host: '0.0.0.0',
    // Accept the `vite` hostname used by Rails' ViteRuby proxy in Docker.
    allowedHosts: true,
  },
});
