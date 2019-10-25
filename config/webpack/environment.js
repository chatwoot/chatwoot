const { environment } = require('@rails/webpacker');
const { VueLoaderPlugin } = require('vue-loader');
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

module.exports = environment;
