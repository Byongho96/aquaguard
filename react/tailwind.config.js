/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        surface: '#F7F8FA',
        panel: '#F3F4F6',
        accent: '#F97316',
        danger: '#EF4444',
        warning: '#F59E0B',
        info: '#0EA5E9',
        dark: '#111827',
        muted: '#6B7280'
      }
    }
  },
  plugins: []
};
