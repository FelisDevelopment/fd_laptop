const defaultTheme = require('tailwindcss/defaultTheme')

/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{html,svelte,js,ts,jsx,tsx}'],
  theme: {
    extend: {
      screens: {
        hd: '1921px'
      },
      fontFamily: {
        sans: ['Inter', ...defaultTheme.fontFamily.sans]
      }
    }
  },
  variants: {},
  plugins: [
    require('tailwind-scrollbar')({ nocompatible: true, preferredStrategy: 'pseudoelements' })
  ]
}
