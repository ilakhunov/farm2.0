import type { Config } from 'tailwindcss';

export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#2E7D32',
          light: '#60AD5E',
          dark: '#005005'
        }
      }
    }
  },
  plugins: []
} satisfies Config;
