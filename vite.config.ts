// <reference types="vitest" />

import { defineConfig } from 'vite';
import ruby from 'vite-plugin-ruby';
import path from 'path';
import vue from '@vitejs/plugin-vue';
import type { UserConfig } from 'vite';

const isLibraryMode = process.env.BUILD_MODE === 'library';
const isTestMode = process.env.TEST === 'true';

const vueOptions = {
  template: {
    compilerOptions: {
      isCustomElement: tag => ['ninja-keys'].includes(tag),
      hoistStatic: true,
    },
  },
  reactivityTransform: true,
};

let plugins = [ruby(), vue(vueOptions)];

if (isLibraryMode) {
  plugins = [];
} else if (isTestMode) {
  plugins = [vue(vueOptions)];
}

export default defineConfig({
  plugins: plugins,
  css: {
    preprocessorOptions: {
      scss: {
        api: 'modern-compiler', // Required for sass-embedded
        silenceDeprecations: ['legacy-js-api'], // Suppress Dart Sass 2.0 warnings
        additionalData: `
          @use "sass:color";
          @use "sass:math";
          @use "dashboard/assets/scss/variables" as variables; // Namespaced imports
          @use "widget/assets/scss/variables" as widget-vars;
        `,
      },
    },
    postcss: {
      plugins: [
        require('autoprefixer'),
        require('postcss-preset-env')({ stage: 3 }),
      ],
    },
  },
  build: {
    cssCodeSplit: true,
    minify: isLibraryMode ? false : 'esbuild',
    sourcemap: true,
    rollupOptions: {
      output: {
        assetFileNames: ({ name }) => {
          if (/\.(css|scss)$/.test(name ?? '')) {
            return 'assets/css/[name]-[hash].css';
          }
          return 'assets/[name]-[hash].[ext]';
        },
        ...(isLibraryMode
          ? {
              dir: 'public/packs',
              entryFileNames: chunkInfo => {
                if (chunkInfo.name === 'sdk') {
                  return 'js/sdk.js';
                }
                return '[name].js';
              },
            }
          : {}),
        inlineDynamicImports: isLibraryMode,
      },
    },
    lib: isLibraryMode
      ? {
          entry: path.resolve(__dirname, './app/javascript/entrypoints/sdk.js'),
          formats: ['iife'],
          name: 'sdk',
        }
      : undefined,
  },
  resolve: {
    alias: [
      { find: 'vue', replacement: 'vue/dist/vue.esm-bundler.js' },
      { find: 'components', replacement: path.resolve('./app/javascript/dashboard/components') },
      { find: 'next', replacement: path.resolve('./app/javascript/dashboard/components-next') },
      { find: 'v3', replacement: path.resolve('./app/javascript/v3') },
      { find: 'dashboard', replacement: path.resolve('./app/javascript/dashboard') },
      { find: 'helpers', replacement: path.resolve('./app/javascript/shared/helpers') },
      { find: 'shared', replacement: path.resolve('./app/javascript/shared') },
      { find: 'survey', replacement: path.resolve('./app/javascript/survey') },
      { find: 'widget', replacement: path.resolve('./app/javascript/widget') },
      { find: 'assets', replacement: path.resolve('./app/javascript/dashboard/assets') },
    ],
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
    setupFiles: ['fake-indexeddb/auto', 'vitest.setup.js'],
    mockReset: true,
    clearMocks: true,
  },
} as UserConfig);
