import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [vue()],
  server: {
    proxy: {
      // Proxy /api requests to the backend services
      // This assumes we'll have an API gateway in front of our microservices
      // running on port 8000 in development.
      '/api': {
        target: 'http://localhost:8000', // This would be the API Gateway
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
})
