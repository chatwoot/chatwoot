const path = require('path');
const resolve = require('../config/webpack/resolve');

// Chatwoot's webpack.config.js
process.env.NODE_ENV = 'development';
const custom = require('../config/webpack/environment');

module.exports = {
  stories: [
    '../stories/**/*.stories.mdx',
    '../app/javascript/**/*.stories.@(js|jsx|ts|tsx)',
  ],
  addons: [
    {
      name: '@storybook/addon-docs',
      options: {
        vueDocgenOptions: {
          alias: {
            '@': path.resolve(__dirname, '../'),
          },
        },
      },
    },
    '@storybook/addon-links',
    '@storybook/addon-essentials',
    {
      /**
       * Fix Storybook issue with PostCSS@8
       * @see https://github.com/storybookjs/storybook/issues/12668#issuecomment-773958085
       */
      name: '@storybook/addon-postcss',
      options: {
        postcssLoaderOptions: {
          implementation: require('postcss'),
        },
      },
    },
  ],
  webpackFinal: config => {
    const newConfig = {
      ...config,
      resolve: {
        ...config.resolve,
        modules: custom.resolvedModules.map(i => i.value),
      },
    };

    newConfig.module.rules.push({
      test: /\.scss$/,
      use: ['style-loader', 'css-loader', 'postcss-loader', 'sass-loader'],
      include: path.resolve(__dirname, '../app/javascript'),
    });

    return newConfig;
  },
};
