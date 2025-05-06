import { defineConfig } from 'vite';
import ruby from 'vite-plugin-ruby';
import path from 'path';
import vue from '@vitejs/plugin-vue';

const isLibraryMode = process.env.BUILD_MODE === 'library';
const isTestMode = process.env.TEST === 'true';
const isProd = process.env.NODE_ENV === 'production';

const vueOptions = {
  template: {
    compilerOptions: {
      isCustomElement: tag => ['ninja-keys'].includes(tag),
    },
    // Handle ::v-deep deprecation warnings
    transformAssetUrls: {},
  },
};

let plugins = [ruby(), vue(vueOptions)];

if (isLibraryMode) {
  plugins = [];
} else if (isTestMode) {
  plugins = [vue(vueOptions)];
}

export default defineConfig({
  plugins: plugins,
  build: {
    // Increase chunk size limit to avoid excessive warnings
    chunkSizeWarningLimit: 2000,

    // Split vendor chunks for better caching and memory management
    rollupOptions: {
      output: {
        // Keep existing library mode functionality
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
          : {
              // When not in library mode, split chunks more aggressively
              // eslint-disable-next-line consistent-return
              manualChunks: id => {
                if (id.includes('node_modules')) {
                  // Group common large dependencies together
                  if (id.includes('vue') || id.includes('@vue')) {
                    return 'vendor-vue';
                  }
                  if (
                    id.includes('lodash') ||
                    id.includes('dayjs') ||
                    id.includes('axios') ||
                    id.includes('i18n')
                  ) {
                    return 'vendor-utils';
                  }
                  // Group remaining node_modules
                  return 'vendor';
                }
              },
            }),
        inlineDynamicImports: isLibraryMode, // Disable code-splitting for SDK
      },
    },
    lib: isLibraryMode
      ? {
          entry: path.resolve(__dirname, './app/javascript/entrypoints/sdk.js'),
          formats: ['iife'], // IIFE format for single file
          name: 'sdk',
        }
      : undefined,

    // Avoid OOM errors by writing larger chunks to disk during build
    reportCompressedSize: !isProd, // Disable in prod to save memory
    minify: isProd ? 'esbuild' : false, // Use faster minifier
  },

  // Handle Sass deprecation warnings
  css: {
    preprocessorOptions: {
      scss: {
        quietDeps: true, // Suppress Sass deprecation warnings
      },
    },
  },

  // Control logging level to reduce noise from warnings
  logLevel: isProd ? 'error' : 'info',

  // Apply existing resolve configuration
  resolve: {
    alias: {
      vue: 'vue/dist/vue.esm-bundler.js',
      components: path.resolve('./app/javascript/dashboard/components'),
      next: path.resolve('./app/javascript/dashboard/components-next'),
      v3: path.resolve('./app/javascript/v3'),
      dashboard: path.resolve('./app/javascript/dashboard'),
      helpers: path.resolve('./app/javascript/shared/helpers'),
      shared: path.resolve('./app/javascript/shared'),
      survey: path.resolve('./app/javascript/survey'),
      widget: path.resolve('./app/javascript/widget'),
      assets: path.resolve('./app/javascript/dashboard/assets'),
    },
  },

  // Keep existing test configuration
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

  // Override esbuild to ignore certain warnings
  esbuild: {
    logOverride: {
      'unsupported-css-property': 'silent',
    },
  },
});
