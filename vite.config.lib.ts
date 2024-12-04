import { defineConfig } from 'vite';
import path from 'path';
import baseConfig from './vite.config.base';
import { mergeConfig } from 'vite';

const libraryConfig = defineConfig({
  plugins: [],
  build: {
    rollupOptions: {
      output: {
        dir: 'public/packs',
        entryFileNames: chunkInfo => {
          if (chunkInfo.name === 'sdk') {
            return 'js/sdk.js';
          }
          return '[name].js';
        },
        inlineDynamicImports: true, // Disable code-splitting for SDK
      },
    },
    lib: {
      entry: path.resolve(__dirname, './app/javascript/entrypoints/sdk.js'),
      formats: ['iife'], // IIFE format for single file
      name: 'sdk',
    },
  },
});

export default mergeConfig(baseConfig, libraryConfig);
