const { environment } = require('@rails/webpacker')
const { VueLoaderPlugin } = require('vue-loader')
const vue = require('./loaders/vue')
const path = require('path')
environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin())
environment.loaders.prepend('vue', vue)
environment.loaders.append('audio', {
  test: /\.(mp3)(\?.*)?$/,
  loader: 'url-loader',
  query: {
    limit: 10000,
    name: 'audio/[name].[ext]'
  },
})

const resolve = {
  alias: {
    'vue$': 'vue/dist/vue.common.js',
    'src': path.resolve('./app/javascript/src'),
    'assets': path.resolve('./app/javascript/src/assets'),
    'components': path.resolve('./app/javascript/src/components')
  },
};

environment.config.merge({ resolve });

module.exports = environment
