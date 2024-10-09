const defaultTheme = require('tailwindcss/defaultTheme')

/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ['selector', '[class="dark-app"]'],
  content: ['./index.html', './src/**/*.{html,vue,js,ts,jsx,tsx}'],
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
    require('tailwindcss-primeui'),
    require('tailwind-scrollbar')({ nocompatible: true, preferredStrategy: 'pseudoelements' })
  ]
}
