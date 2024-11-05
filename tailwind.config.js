const { slateDark } = require('@radix-ui/colors');
import { colors } from './theme/colors';
const defaultTheme = require('tailwindcss/defaultTheme');
const {
  iconsPlugin,
  getIconCollections,
} = require('@egoist/tailwindcss-icons');

const defaultSansFonts = [
  '-apple-system',
  'system-ui',
  'BlinkMacSystemFont',
  '"Segoe UI"',
  'Roboto',
  '"Helvetica Neue"',
  'Tahoma',
  'Arial',
  'sans-serif !important',
];

const tailwindConfig = {
  darkMode: 'class',
  content: [
    './enterprise/app/views/**/*.html.erb',
    './app/javascript/widget/**/*.vue',
    './app/javascript/v3/**/*.vue',
    './app/javascript/dashboard/**/*.vue',
    './app/javascript/portal/**/*.vue',
    './app/javascript/shared/**/*.vue',
    './app/javascript/survey/**/*.vue',
    './app/javascript/dashboard/helper/**/*.js',
    './app/views/**/*.html.erb',
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: defaultSansFonts,
        inter: ['Inter', ...defaultSansFonts],
        interDisplay: ['Inter Display', ...defaultSansFonts],
      },
    },
    screens: {
      xs: '480px',
      sm: '640px',
      md: '768px',
      lg: '1024px',
      xl: '1280px',
      '2xl': '1536px',
    },
    fontSize: {
      ...defaultTheme.fontSize,
      xxs: '0.625rem',
    },
    colors: {
      transparent: 'transparent',
      white: '#fff',
      'modal-backdrop-light': 'rgba(0, 0, 0, 0.4)',
      'modal-backdrop-dark': 'rgba(0, 0, 0, 0.6)',
      current: 'currentColor',
      ...colors,
      body: slateDark.slate7,
    },
    keyframes: {
      ...defaultTheme.keyframes,
      wiggle: {
        '0%': { transform: 'translateX(0)' },
        '15%': { transform: 'translateX(0.375rem)' },
        '30%': { transform: 'translateX(-0.375rem)' },
        '45%': { transform: 'translateX(0.375rem)' },
        '60%': { transform: 'translateX(-0.375rem)' },
        '75%': { transform: 'translateX(0.375rem)' },
        '90%': { transform: 'translateX(-0.375rem)' },
        '100%': { transform: 'translateX(0)' },
      },
      'fade-in-up': {
        '0%': { opacity: 0, transform: 'translateY(0.5rem)' },
        '100%': { opacity: 1, transform: 'translateY(0)' },
      },
      'loader-pulse': {
        '0%': { opacity: 0.4 },
        '50%': { opacity: 1 },
        '100%': { opacity: 0.4 },
      },
      'card-select': {
        '0%, 100%': {
          transform: 'translateX(0)',
        },
        '50%': {
          transform: 'translateX(1px)',
        },
      },
      shake: {
        '0%, 100%': { transform: 'translateX(0)' },
        '25%': { transform: 'translateX(0.234375rem)' },
        '50%': { transform: 'translateX(-0.234375rem)' },
        '75%': { transform: 'translateX(0.234375rem)' },
      },
    },
    animation: {
      ...defaultTheme.animation,
      wiggle: 'wiggle 0.5s ease-in-out',
      'fade-in-up': 'fade-in-up 0.3s ease-out',
      'loader-pulse': 'loader-pulse 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite',
      'card-select': 'card-select 0.25s ease-in-out',
      shake: 'shake 0.3s ease-in-out 0s 2',
    },
  },
  plugins: [
    // eslint-disable-next-line
    require('@tailwindcss/typography'),
    iconsPlugin({
      collections: {
        woot: {
          icons: {
            'match-and': {
              body: `<path fill-rule="evenodd" clip-rule="evenodd" d="M14.4242 19.3756C15.4864 19.9889 16.7203 19.8402 17.1802 19.0436C17.6401 18.2469 17.1519 17.104 16.0898 16.4908C15.2524 16.0073 14.3082 15.9974 13.7208 16.4052L1.59118 9.40216C1.32564 9.24885 0.98609 9.33983 0.832779 9.60537C0.679468 9.87092 0.77045 10.2105 1.03599 10.3638L13.1656 17.3668C13.1062 18.0795 13.5868 18.8921 14.4242 19.3756Z" fill="currentColor"/>
              <path d="M13.1705 7.38466C13.5386 7.38466 13.8917 7.23843 14.152 6.97813C14.4123 6.71784 14.5585 6.3648 14.5585 5.99669C14.5585 5.23053 14.2809 4.88631 14.0033 4.33113C13.4081 3.14136 13.8789 2.0804 15.1137 1C15.3913 2.38797 16.2241 3.72042 17.3344 4.60872C18.4448 5.49702 19 6.55188 19 7.66225C19 8.17261 18.8995 8.67797 18.7042 9.14948C18.5089 9.62099 18.2226 10.0494 17.8617 10.4103C17.5008 10.7712 17.0724 11.0574 16.6009 11.2527C16.1294 11.448 15.624 11.5486 15.1137 11.5486C14.6033 11.5486 14.098 11.448 13.6265 11.2527C13.1549 11.0574 12.7265 10.7712 12.3656 10.4103C12.0048 10.0494 11.7185 9.62099 11.5232 9.14948C11.3279 8.67797 11.2274 8.17261 11.2274 7.66225C11.2274 7.02212 11.4678 6.38865 11.7826 5.99669C11.7826 6.3648 11.9288 6.71784 12.1891 6.97813C12.4494 7.23843 12.8024 7.38466 13.1705 7.38466Z" fill="currentColor" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>`,
              width: 20,
              height: 20,
            },
            'match-or': {
              body: `<path fill-rule="evenodd" clip-rule="evenodd" d="M14.509 19.3571C15.5774 19.9828 16.8186 19.8311 17.2812 19.0183C17.7438 18.2055 17.2527 17.0394 16.1843 16.4137C15.342 15.9205 14.3924 15.9103 13.8014 16.3264L1.60399 9.18333C1.33498 9.02579 0.991888 9.11771 0.837676 9.38864C0.683464 9.65957 0.776527 10.0069 1.04554 10.1645L13.243 17.3075C13.1832 18.0347 13.6667 18.8638 14.509 19.3571Z" fill="currentColor"/>
              <path d="M12.9017 7.77472C13.2868 7.77472 13.6561 7.61956 13.9284 7.34336C14.2007 7.06716 14.3537 6.69256 14.3537 6.30196C14.3537 5.48899 14.0633 5.12374 13.7729 4.53464C13.1503 3.27218 13.6428 2.1464 14.9345 1C15.2249 2.47277 16.0961 3.88662 17.2576 4.82919C18.4192 5.77176 19 6.89106 19 8.06928C19 8.61081 18.8948 9.14705 18.6905 9.64736C18.4862 10.1477 18.1868 10.6023 17.8092 10.9852C17.4317 11.3681 16.9835 11.6719 16.4903 11.8791C15.997 12.0864 15.4684 12.193 14.9345 12.193C14.4006 12.193 13.8719 12.0864 13.3787 11.8791C12.8854 11.6719 12.4373 11.3681 12.0598 10.9852C11.6822 10.6023 11.3828 10.1477 11.1785 9.64736C10.9742 9.14705 10.869 8.61081 10.869 8.06928C10.869 7.39004 11.1205 6.71787 11.4498 6.30196C11.4498 6.69256 11.6028 7.06716 11.8751 7.34336C12.1473 7.61956 12.5167 7.77472 12.9017 7.77472Z" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round"/>`,
              width: 20,
              height: 20,
            },
            alert: {
              body: `<path d="M1.81348 0.9375L1.69727 7.95117H0.302734L0.179688 0.9375H1.81348ZM1 11.1025C0.494141 11.1025 0.0908203 10.7061 0.0976562 10.2207C0.0908203 9.72852 0.494141 9.33203 1 9.33203C1.49219 9.33203 1.89551 9.72852 1.90234 10.2207C1.89551 10.7061 1.49219 11.1025 1 11.1025Z" fill="currentColor" />`,
              width: 2,
              height: 12,
            },
          },
        },
        ...getIconCollections(['lucide', 'logos', 'ri']),
      },
    }),
  ],
};

module.exports = tailwindConfig;
