const path = require('path');
const resolve = require('../config/webpack/resolve');

// Chatwoot's webpack.config.js
process.env.NODE_ENV = 'development';
const custom = require('../config/webpack/environment');

module.exports = {
  stories: [
    '../stories/**/*.stories.mdx',
    '../app/javascript/dashboard/components/ui/stories/**/*.stories.@(js|jsx|ts|tsx)',
    '../stories/**/*.stories.@(js|jsx|ts|tsx)',
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
      use: ['style-loader', 'css-loader', 'sass-loader'],
      include: path.resolve(__dirname, '../app/javascript'),
    });

    return newConfig;
  },
};
