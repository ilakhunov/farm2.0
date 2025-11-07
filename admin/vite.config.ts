import react from '@vitejs/plugin-react';
import { defineConfig, loadEnv } from 'vite';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  return {
    plugins: [react()],
    server: {
      port: 5173,
    },
    define: {
      __API_BASE_URL__: JSON.stringify(env.VITE_API_BASE_URL ?? 'http://localhost:8000/api/v1'),
    },
  };
});
