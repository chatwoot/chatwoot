import { defineConfig } from 'vite'
import vueJsx from '@vitejs/plugin-vue2-jsx'
import vue from '@vitejs/plugin-vue2'
import path from 'path';

export default defineConfig({
  plugins: [vueJsx({
    include: '/\.js$/',
  }), vue()],
  resolve: {
    alias: {
      "dashboard": path.resolve(__dirname, "./"),
    }
  }
})
