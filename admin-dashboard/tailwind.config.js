/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      fontFamily: {
        sans: ['Cairo', 'system-ui', 'sans-serif'],
      },
      // ── Unified semantic color tokens (single source of truth) ──────────
      // `brand` == `primary` == AzBerry logo orange. The green scale moved to
      // `success` (used for delivered/positive states). `warning` = amber,
      // `danger` = red. Prefer these names over raw slate/red literals.
      colors: {
        // Primary — AzBerry logo orange ("Az" burnt-orange).
        brand: {
          50: '#fff4ed',
          100: '#ffe4d4',
          200: '#fdc9a6',
          400: '#f87f3f',
          500: '#f26430',
          600: '#e4531c', // primary base — matches the logo
          700: '#bc4116',
        },
        // Alias so new code can use the semantic name `primary-*`.
        primary: {
          50: '#fff4ed',
          100: '#ffe4d4',
          200: '#fdc9a6',
          400: '#f87f3f',
          500: '#f26430',
          600: '#e4531c',
          700: '#bc4116',
        },
        // Success / "fresh & healthy" — the former brand green, now secondary.
        success: {
          50: '#f0fdf4',
          100: '#dcfce7',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
        },
        warning: {
          50: '#fffbeb',
          100: '#fef3c7',
          500: '#f59e0b',
          600: '#d97706',
        },
        danger: {
          50: '#fef2f2',
          100: '#fee2e2',
          500: '#ef4444',
          600: '#dc2626',
          700: '#b91c1c',
        },
      },
    },
  },
  plugins: [],
}
