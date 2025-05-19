import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { nodePolyfills } from 'vite-plugin-node-polyfills'

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    nodePolyfills({
      // 是否包含 Node.js 全局变量的 polyfill
      globals: {
        Buffer: true,
        global: true,
        process: true,
      },
      // 是否包含 Node.js 内置模块的 polyfill
      protocolImports: true,
    }),
  ],
  server: {
    host: '127.0.0.1',
    port: 3000,
    strictPort: true,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:3000',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api/, '')
      }
    }
  },
  resolve: {
    alias: {
      // 处理 buffer 模块
      buffer: 'buffer',
    },
  },
  define: {
    // 处理 process.env
    'process.env': {},
  },
  optimizeDeps: {
    esbuildOptions: {
      // Node.js 全局变量
      define: {
        global: 'globalThis',
      },
    },
  },
})
