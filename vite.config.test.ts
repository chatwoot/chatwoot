import { defineConfig } from 'vite';
import vue from '@vitejs/plugin-vue';
import baseConfig from './vite.config.base';
import { mergeConfig } from 'vite';

const vueOptions = {
  template: {
    compilerOptions: {
      isCustomElement: tag => ['ninja-keys'].includes(tag),
    },
  },
};

const testConfig = defineConfig({
  plugins: [vue(vueOptions)],
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
});

export default mergeConfig(baseConfig, testConfig);
