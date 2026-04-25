import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
// test CI/CD trigger
// https://vite.dev/config/
export default defineConfig({
  define: {
    global: 'globalThis',
  },
  plugins: [
    react(),
  ],
  server: {
    proxy: {
      '/api': {
        target: 'https://k713nuvb74.execute-api.ap-south-1.amazonaws.com/prod',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, ''),
      },
    },
  },
})
