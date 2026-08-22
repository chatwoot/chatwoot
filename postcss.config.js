/* eslint-disable */
module.exports = {
  plugins: [
    require('postcss-import'),
    require('postcss-preset-env')({
      autoprefixer: {
        flexbox: 'no-2009',
      },
      stage: 3,
    }),
    require('tailwindcss'),
  ],
};
