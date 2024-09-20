/// <reference types="vitest" />
import { defineConfig } from 'vite';
import ruby from 'vite-plugin-ruby';
import path from 'path';
import vue from '@vitejs/plugin-vue';

export default defineConfig({
  plugins: [
    ruby(),
    vue({
      template: {
        compilerOptions: {
          isCustomElement: tag => ['ninja-keys'].includes(tag),
        },
      },
    }),
  ],
  build: {
    rollupOptions: {
      output: {
        inlineDynamicImports: false,
      },
      input: {
        sdk: path.resolve(__dirname, './app/javascript/entrypoints/sdk.js'),
      },
    },
  },
  resolve: {
    alias: {
      components: path.resolve('./app/javascript/dashboard/components'),
      v3: path.resolve('./app/javascript/v3'),
      dashboard: path.resolve('./app/javascript/dashboard'),
      helpers: path.resolve('./app/javascript/shared/helpers'),
      shared: path.resolve('./app/javascript/shared'),
      survey: path.resolve('./app/javascript/survey'),
      widget: path.resolve('./app/javascript/widget'),
      assets: path.resolve('./app/javascript/dashboard/assets'),
    },
  },
  test: {
    environment: 'jsdom',
    include: ['app/**/*.{test,spec}.?(c|m)[jt]s?(x)'],
    coverage: {
      reporter: ['lcov', 'text'],
      include: ['app/**/*.js', 'app/**/*.vue'],
      exclude: [
        'app/**/*.@(spec|stories|routes).js',
        '**/specs/**/*',
        '**/i18n/**/*',
      ],
    },
    globals: true,
    outputFile: 'coverage/sonar-report.xml',
    server: {
      deps: {
        inline: ['tinykeys', '@material/mwc-icon'],
      },
    },
    setupFiles: ['fake-indexeddb/auto'],
    mockReset: true,
    clearMocks: true,
  },
});
