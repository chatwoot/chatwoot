import path from 'path';

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
        // Use the modern Sass compiler API for faster stylesheet compilation.
        api: 'modern-compiler',
        // The codebase (and some third-party deps like vue-datepicker-next) still
        // rely on legacy Sass features Dart Sass deprecates and will remove in
        // 3.0.0: the `@import` rule and global built-in functions such as `mix()`.
        // Silence those specific deprecation warnings until the stylesheets are
        // migrated to `@use` / `color.mix`.
        silenceDeprecations: ['import', 'global-builtin'],
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
