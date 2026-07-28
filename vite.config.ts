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
    // Vite >= 6 rejects any request whose Host header is not in `allowedHosts`
    // (localhost and bare IPs are permitted by default). When Rails and Vite run
    // as separate compose services, vite_ruby's DevServerProxy forwards asset
    // requests to `http://vite:3036` with `Host: vite` — which Vite refuses:
    //
    //   403  Blocked request. This host ("vite") is not allowed.
    //
    // Rails still returns the HTML document, so the page looks "up" while every
    // script tag 404s and the SPA never boots — a blank screen with a 200.
    //
    // Additive and inert by default: unset, this is `[]`, which is exactly
    // Vite's own default. Set VITE_ALLOWED_HOSTS (comma-separated) only in the
    // dev compose. See docker-compose.yaml.
    allowedHosts:
      process.env.VITE_ALLOWED_HOSTS?.split(',')
        .map(host => host.trim())
        .filter(Boolean) ?? [],
  },
});
