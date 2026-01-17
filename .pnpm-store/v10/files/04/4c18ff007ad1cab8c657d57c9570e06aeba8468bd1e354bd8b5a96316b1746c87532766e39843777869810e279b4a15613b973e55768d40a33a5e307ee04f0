/// <reference types="vitest" />

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [
    vue(),
  ],
  resolve: {
    alias: process.env.VITEST
      ? {}
      : {
          'floating-vue': '@histoire/vendors/floating-vue',
          '@iconify/vue': '@histoire/vendors/iconify',
          'pinia': '@histoire/vendors/pinia',
          'scroll-into-view-if-needed': '@histoire/vendors/scroll',
          'vue-router': '@histoire/vendors/vue-router',
          '@vueuse/core': '@histoire/vendors/vue-use',
          'vue': '@histoire/vendors/vue',
        },
  },

  build: {
    emptyOutDir: false,

    lib: {
      entry: 'src/index.ts',
      formats: [
        'es',
      ],
      fileName: 'index.es',
    },

    rollupOptions: {
      external: [
        /@histoire/,
      ],
    },
  },

  test: {
    environment: 'jsdom',
    globals: true,
  },
})
