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
    './app/javascript/dashboard/components-next/**/*.js',
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
            'logic-or': {
              body: `<rect x="14" y="5" width="2" height="13" rx="1" fill="currentColor"/><rect x="8" y="5" width="2" height="13" rx="1" fill="currentColor"/>`,
              width: 24,
              height: 24,
            },
            alert: {
              body: `<path d="M1.81348 0.9375L1.69727 7.95117H0.302734L0.179688 0.9375H1.81348ZM1 11.1025C0.494141 11.1025 0.0908203 10.7061 0.0976562 10.2207C0.0908203 9.72852 0.494141 9.33203 1 9.33203C1.49219 9.33203 1.89551 9.72852 1.90234 10.2207C1.89551 10.7061 1.49219 11.1025 1 11.1025Z" fill="currentColor" />`,
              width: 2,
              height: 12,
            },
            captain: {
              body: `<path d="M150.485 213.282C150.485 200.856 160.559 190.782 172.985 190.782C185.411 190.782 195.485 200.856 195.485 213.282V265.282C195.485 277.709 185.411 287.782 172.985 287.782C160.559 287.782 150.485 277.709 150.485 265.282V213.282Z" fill="currentColor"/>
              <path d="M222.485 213.282C222.485 200.856 232.559 190.782 244.985 190.782C257.411 190.782 267.485 200.856 267.485 213.282V265.282C267.485 277.709 257.411 287.782 244.985 287.782C232.559 287.782 222.485 277.709 222.485 265.282V213.282Z" fill="currentColor"/>
              <path fill-rule="evenodd" clip-rule="evenodd" d="M412.222 109.961C317.808 96.6217 240.845 96.0953 144.309 109.902C119.908 113.392 103.762 115.751 91.4521 119.354C80.0374 122.694 73.5457 126.678 68.1762 132.687C57.0576 145.13 55.592 159.204 54.0765 208.287C52.587 256.526 55.5372 299.759 61.1249 348.403C64.1025 374.324 66.1515 391.817 69.4229 405.117C72.526 417.732 76.2792 424.515 81.4954 429.708C86.7533 434.942 93.4917 438.633 105.859 441.629C118.94 444.797 136.104 446.713 161.613 449.5C244.114 458.514 305.869 458.469 388.677 449.548C414.495 446.767 431.939 444.849 445.216 441.702C457.83 438.712 464.612 435.047 469.797 429.962C474.873 424.985 478.752 418.118 482.116 404.874C485.626 391.056 488.014 372.772 491.47 345.913C497.636 297.99 502.076 255.903 502.248 209.798C502.433 160.503 501.426 146.477 490.181 133.468C484.75 127.185 478.148 123.053 466.473 119.612C453.865 115.897 437.283 113.502 412.222 109.961ZM138.414 68.5711C238.977 54.1882 319.888 54.7514 418.047 68.6199L419.483 68.8227C442.724 72.1054 462.359 74.8786 478.244 79.5601C495.387 84.6124 509.724 92.2821 521.706 106.145C544.308 132.295 544.161 163.321 543.965 204.542C543.956 206.327 543.948 208.131 543.941 209.954C543.758 258.703 539.048 302.844 532.821 351.247L532.656 352.528C529.407 377.787 526.729 398.602 522.522 415.166C518.098 432.584 511.485 447.517 498.968 459.792C486.56 471.959 471.897 478.282 454.819 482.33C438.691 486.153 418.624 488.314 394.436 490.919L393.136 491.059C307.385 500.297 242.618 500.349 157.091 491.004L155.772 490.86C131.921 488.255 112.062 486.086 96.056 482.209C79.0408 478.087 64.4759 471.637 52.1005 459.316C39.6835 446.955 33.1618 432.265 28.94 415.102C24.9582 398.915 22.6435 378.759 19.8561 354.488L19.7052 353.174C13.9746 303.287 10.8315 257.908 12.4035 206.997C12.4606 205.15 12.5151 203.323 12.5691 201.516C13.7911 160.603 14.7077 129.914 37.1055 104.847C48.989 91.5477 63.035 84.1731 79.7563 79.2794C95.2643 74.7408 114.386 72.0068 137.018 68.7707C137.482 68.7044 137.948 68.6379 138.414 68.5711Z" fill="currentColor"/>`,
              width: 556,
              height: 556,
            },
          },
        },
        ...getIconCollections(['lucide', 'logos', 'ri', 'ph']),
      },
    }),
  ],
};

module.exports = tailwindConfig;
