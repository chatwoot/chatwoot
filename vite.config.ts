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
  // Resolve the asset base at runtime via window.__VITE_BASE__ instead of
  // baking VITE_RUBY_ASSET_HOST into chunk imports at build time. The server
  // injects __VITE_BASE__ before any Vite chunk loads (see
  // app/views/shared/_vite_base.html.erb) so the same pre-built image can be
  // pointed at any ASSET_CDN_HOST by changing only the runtime env. The
  // '/vite/' fallback keeps deployments without ASSET_CDN_HOST working
  // origin-relative. The SDK build (vite.lib.config.ts) doesn't need this
  // because it ships as a single IIFE without dynamic imports. See:
  // https://vite.dev/guide/build#advanced-base-options (#13687)
  experimental: {
    renderBuiltUrl(filename, { hostType }) {
      if (hostType === 'js') {
        return {
          runtime: `(window.__VITE_BASE__ || '/vite/') + ${JSON.stringify(filename)}`,
        };
      }
      // CSS/HTML asset references: emit relative paths so the browser
      // resolves them against the stylesheet/document URL (which is
      // itself served from whatever __VITE_BASE__ points at).
      return { relative: true };
    },
  },
  resolve: { alias: aliases },
});
