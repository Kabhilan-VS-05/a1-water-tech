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
})
