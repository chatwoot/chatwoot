import { resolve } from 'path'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { createVuePlugin as Vue2Plugin } from 'vite-plugin-vue2'
import { brotliCompressSync } from "zlib";
import gzipPlugin from "rollup-plugin-gzip";

export default defineConfig({
  plugins: [
    RubyPlugin(),
    Vue2Plugin(),
    gzipPlugin(),
    // Create brotli copies of relevant assets
    gzipPlugin({
      customCompression: (content) => brotliCompressSync(Buffer.from(content)),
      fileName: ".br",
    }),
  ],
  resolve: {
    alias: {
      assets: resolve('./app/javascript/dashboard/assets'),
      components: resolve('./app/javascript/dashboard/components'),
      dashboard: resolve('./app/javascript/dashboard'),
      shared: resolve('./app/javascript/shared'),
      survey: resolve('./app/javascript/survey'),
      widget: resolve('./app/javascript/widget'),
      '~widget': resolve('./app/javascript/widget'),
      '~survey': resolve('./app/javascript/survey'),
      '~dashboard': resolve('./app/javascript/dashboard'),
      vue: 'vue/dist/vue.js'
    },
  },
  define: {
    'process.env': process.env
  },
  build: {
    lib: {
      entry: resolve(__dirname, 'app/javascript/packs/sdk.js'),
      name: 'ChatwootWidgetSDK',
      fileName: () => `packs/js/sdk.js`,
      formats: ['cjs']
    },
  },
  css: { preprocessorOptions: { scss: { charset: false } } },
  esbuild: {
    jsxFactory: 'h',
    jsxFragment: 'Fragment'
  }
})
