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
        // Use the modern Sass JS API. The native `sass-embedded` compiler
        // (api: 'modern-compiler') runs as a child process over a pipe; when a
        // client disconnects mid-compilation (frequent under HMR in Docker/WSL)
        // writing to the closed pipe throws an unhandled EPIPE that crashes the
        // whole dev server, leaving the frontend half-loaded. The pure-JS `sass`
        // compiler avoids that subprocess and is stable here.
        api: 'modern',
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
    // Pre-transform the dashboard/v3 entries and the global SCSS while the
    // dev server boots, instead of lazily on the first page request. The SCSS
    // (tailwind + plugins) cold-compiles in tens of seconds over the Docker/WSL
    // bind mount, and doing that at startup rather than on the first visit
    // makes the initial page load near-instant and removes the white-page
    // flash behind the loading placeholder.
    warmup: {
      clientFiles: [
        './app/javascript/entrypoints/dashboard.js',
        './app/javascript/entrypoints/v3app.js',
        './app/javascript/dashboard/App.vue',
        './app/javascript/v3/App.vue',
        './app/javascript/dashboard/assets/scss/app.scss',
      ],
    },
    watch: {
      // A .env change makes Vite tear down and rebuild the whole dev server,
      // and that internal restart has hung mid-flight in Docker, leaving the
      // process alive with no listening port while the container looks
      // healthy. The frontend gets its config from Rails anyway, so require
      // an explicit `docker compose restart vite` instead.
      //
      // The config files are ignored for the same reason: with chokidar
      // polling over the Docker/WSL bind mount their mtime flaps spuriously,
      // so Vite kept self-restarting ("vite.config.ts changed, restarting
      // server...") every time the watchdog came up, dropping the HMR
      // websocket and forcing a cold recompile behind a white page. Config
      // edits are rare; require an explicit `docker compose restart vite`.
      ignored: ['**/.env', '**/.env.*', '**/vite.config.ts', '**/vite.shared.ts'],
    },
  },
});
