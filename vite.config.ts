import path from 'path';
import { defineConfig } from 'vite';
import ruby from 'vite-plugin-ruby';
import vue from '@vitejs/plugin-vue';
import { aliases, vueOptions } from './vite.shared';
import yaml from '@rollup/plugin-yaml';

export default defineConfig(({ command }) => {
  // The dev server loads only English locale files unless DEV_ALL_LOCALES is set.
  const englishOnly = command === 'serve' && !process.env.DEV_ALL_LOCALES;

  return {
    plugins: [ruby(), vue(vueOptions), yaml()],
    css: {
      preprocessorOptions: {
        scss: {
          api: 'modern-compiler',
        },
      },
    },
    resolve: {
      alias: {
        ...(englishOnly && {
          'dashboard/i18n': path.resolve(
            './app/javascript/dashboard/i18n/englishOnly.js'
          ),
        }),
        ...aliases,
      },
    },
    // Transform the dashboard module graph at startup, while Rails boots,
    // instead of on the first browser request.
    server: { warmup: { clientFiles: ['./entrypoints/dashboard.js'] } },
  };
});
