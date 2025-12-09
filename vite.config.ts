/// <reference types="vitest" />

/**
What's going on with library mode?

Glad you asked, here's a quick rundown:

1. vite-plugin-ruby will automatically bring all the entrypoints like dashbord and widget as input to vite.
2. vite needs to be in library mode to build the SDK as a single file. (UMD) format and set `inlineDynamicImports` to true.
3. But when setting `inlineDynamicImports` to true, vite will not be able to handle mutliple entrypoints.

This puts us in a deadlock, now there are two ways around this, either add another separate build pipeline to
the app using vanilla rollup or rspack or something. The second option is to remove sdk building from the main pipeline
and build it separately using Vite itself, toggled by an ENV variable.

`BUILD_MODE=library bin/vite build` should build only the SDK and save it to `public/packs/js/sdk.js`
`bin/vite build` will build the rest of the app as usual. But exclude the SDK.

We need to edit the `asset:precompile` rake task to include the SDK in the precompile list.
*/
import { defineConfig } from 'vite';
import ruby from 'vite-plugin-ruby';
import path from 'path';
import vue from '@vitejs/plugin-vue';
import react from '@vitejs/plugin-react';

const isLibraryMode = process.env.BUILD_MODE === 'library';
const uiMode = process.env.BUILD_MODE === 'ui';
const reactComponentMode = process.env.BUILD_MODE === 'react-components';
const isTestMode = process.env.TEST === 'true';

const vueOptions = {
  template: {
    compilerOptions: {
      isCustomElement: tag => ['ninja-keys'].includes(tag),
    },
  },
};

let plugins = [ruby(), vue(vueOptions)];

if (isLibraryMode) {
  plugins = [];
} else if (uiMode) {
  plugins = [vue()];
} else if (reactComponentMode) {
  plugins = [vue({ ...vueOptions, customElement: true }), react()];
} else if (isTestMode) {
  plugins = [vue(vueOptions)];
}

let lib;
let rollupOptions = {};

if (isLibraryMode) {
  lib = {
    entry: path.resolve(__dirname, './app/javascript/entrypoints/sdk.js'),
    formats: ['iife'], // IIFE format for single file
    name: 'sdk',
  };
} else if (uiMode) {
  lib = {
    entry: path.resolve(__dirname, './app/javascript/entrypoints/ui.js'),
    formats: ['iife'], // IIFE format for single file
    name: 'ui',
  };
} else if (reactComponentMode) {
  lib = {
    entry: path.resolve(
      __dirname,
      './app/javascript/react-components/src/index.jsx'
    ),
    formats: ['es', 'cjs'], // ES modules and CommonJS only
    fileName: format => `react-components.${format}.js`,
  };

  rollupOptions = {
    external: ['react', 'react-dom'],
  };
}

const chunkBuilder = chunkInfo => {
  if (chunkInfo.name === 'sdk') {
    return 'js/sdk.js';
  }

  if (chunkInfo.name === 'ui') {
    return `js/ui.js`;
  }

  // For react components, we need to return different names but can't access format here
  // So we'll handle this differently
  return '[name].js';
};

export default defineConfig({
  plugins: plugins,
  define: isTestMode
    ? {}
    : {
        'process.env.NODE_ENV': JSON.stringify('production'),
      },
  build: {
    rollupOptions: {
      ...rollupOptions,
      output: {
        ...rollupOptions.output,
        // [NOTE] when not in library mode, no new keys will be addedd or overwritten
        // setting dir: isLibraryMode ? 'public/packs' : undefined will not work
        ...(isLibraryMode || uiMode
          ? {
              dir: 'public/packs',
              entryFileNames: chunkBuilder,
            }
          : {}),
        ...(reactComponentMode
          ? {
              dir: 'public/packs',
            }
          : {}),
        inlineDynamicImports: isLibraryMode || uiMode || reactComponentMode, // Disable code-splitting for SDK
      },
    },
    lib,
  },
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
    pool: 'threads',
    poolOptions: {
      threads: {
        singleThread: false,
      },
    },
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
