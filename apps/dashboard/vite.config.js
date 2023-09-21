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
      "dashboard": path.resolve(__dirname, "./app"),
      "widget": path.resolve(__dirname, "../widget"),
      vue: 'vue/dist/vue.js'
    }
  },
  define: {
    'process.env': process.env,
    global: {},
  },
  build: {
    rollupOptions: {
      input: {
        unauthenticated: path.resolve(__dirname, 'index.html'),
        authenticated: path.resolve(__dirname, 'app/index.html'),
      },
    },
  },

})
