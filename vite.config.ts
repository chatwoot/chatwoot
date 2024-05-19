import { defineConfig } from 'vite';
import RubyPlugin from 'vite-plugin-ruby';
import path from 'path';
import Vue2Plugin from '@vitejs/plugin-vue2';

export default defineConfig({
  plugins: [RubyPlugin(), Vue2Plugin()],
  resolve: {
    alias: {
      vue: 'vue/dist/vue.esm.js',
      components: path.resolve('./app/javascript/dashboard/components'),
      dashboard: path.resolve('./app/javascript/dashboard'),
      helpers: path.resolve('./app/javascript/shared/helpers'),
      shared: path.resolve('./app/javascript/shared'),
      survey: path.resolve('./app/javascript/survey'),
      widget: path.resolve('./app/javascript/widget'),
    },
  },
});
