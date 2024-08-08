process.env.NODE_ENV = process.env.NODE_ENV || 'production';

const environment = require('./environment');
const { sentryWebpackPlugin } = require('@sentry/webpack-plugin');

module.exports = {
  ...environment.toWebpackConfig(),
  devtool: 'source-map',
  plugins: [
    ...environment.toWebpackConfig().plugins,
    sentryWebpackPlugin({
      authToken: process.env.SENTRY_AUTH_TOKEN,
      org: 'hoatieu-crm',
      project: 'hoatieu-crm',
      dist: 'public/packs/js',
    }),
  ],
};
