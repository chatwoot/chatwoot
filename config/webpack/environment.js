const { environment } = require('@rails/webpacker');
const { VueLoaderPlugin } = require('vue-loader');
const webpack = require('webpack');
const resolve = require('./resolve');
const vue = require('./loaders/vue');

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin());
environment.loaders.prepend('vue', vue);
environment.loaders.append('audio', {
  test: /\.(mp3)(\?.*)?$/,
  loader: 'url-loader',
  query: {
    limit: 10000,
    name: 'audio/[name].[ext]',
  },
});

environment.config.merge({ resolve });

const {
  pusher_cluster: cluster,
  pusher_key: token,
  fb_app_id: fbAppID,
} = process.env;

environment.plugins.prepend(
  'DefinePlugin',
  new webpack.DefinePlugin({
    __PUSHER__: {
      token: `"${token}"`,
      cluster: `"${cluster}"`,
    },
    __FB_ID__: `"${fbAppID}"`,
  })
);

module.exports = environment;
