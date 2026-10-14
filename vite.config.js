import { fileURLToPath, URL } from 'node:url'
import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  resolve: {
    // Permite importar con "@/..." en lugar de rutas relativas (igual que en clase)
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
})
