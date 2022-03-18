import { resolve } from 'path'
import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import { createVuePlugin as Vue2Plugin } from 'vite-plugin-vue2'

export default defineConfig({
  plugins: [
    RubyPlugin(),
    Vue2Plugin()
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
      '~dashboard': resolve('./app/javascript/dashboard')
    },
  },
})
