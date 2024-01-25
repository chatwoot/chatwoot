import { defineConfig } from 'vite';
import RubyPlugin from 'vite-plugin-ruby';
import Vue2 from '@vitejs/plugin-vue2';
import path from 'path';

export default defineConfig({
  plugins: [RubyPlugin(), Vue2()],
  resolve: {
    alias: {
      dashboard: path.resolve('./app/javascript/dashboard'),
      widget: path.resolve('./app/javascript/widget'),
      survey: path.resolve('./app/javascript/survey'),
      assets: path.resolve('./app/javascript/dashboard/assets'),
      components: path.resolve('./app/javascript/dashboard/components'),
      helpers: path.resolve('./app/javascript/shared/helpers'),
      shared: path.resolve('./app/javascript/shared'),
    },
  },
});
