const { environment } = require('@rails/webpacker');
const { VueLoaderPlugin } = require('vue-loader');
const resolve = require('./resolve');
const vue = require('./loaders/vue');

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin());
environment.loaders.prepend('vue', vue);

environment.loaders.append('opus', {
  test: /encoderWorker\.min\.js$/,
  loader: 'file-loader',
  options: {
    name: '[name].[ext]',
  },
});

environment.loaders.append('audio', {
  test: /\.(mp3)(\?.*)?$/,
  use: {
    loader: 'url-loader',
    options: {
      limit: 10000,
      name: 'audio/[name].[ext]',
    }
  },
});

const node = {};

environment.config.delete('node.dgram')
environment.config.delete('node.fs')
environment.config.delete('node.net')
environment.config.delete('node.tls')
environment.config.delete('node.child_process')

environment.config.merge(
  {
    resolve,
    node
  }
);
environment.config.set('output.filename', chunkData => {
  return chunkData.chunk.name === 'sdk'
    ? 'js/[name].js'
    : 'js/[name]-[hash].js';
});

module.exports = environment;
