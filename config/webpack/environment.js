const { environment } = require('@rails/webpacker');
const { VueLoaderPlugin } = require('vue-loader');
const resolve = require('./resolve');
const vue = require('./loaders/vue');

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin());
environment.loaders.prepend('vue', vue);
environment.loaders.append('audio', {
  test: /\.(mp3)(\?.*)?$/,
  use: [
    {
      loader: 'url-loader',
      query: {
        limit: 10000,
        name: 'audio/[name].[ext]',
      },
    },
  ],
});

environment.config.merge({ resolve });
environment.config.set('output.filename', chunkData => {
  return chunkData.chunk.name === 'sdk'
    ? 'js/[name].js'
    : 'js/[name]-[hash].js';
});

const sassLoader = environment.loaders.get('sass');
const sassLoaderConfig = sassLoader.use.find(element => {
  return element.loader === 'sass-loader';
});

// Use Dart-implementation of Sass (default is node-sass)
const options = sassLoaderConfig.options;
options.implementation = require('sass');

function hotfixPostcssLoaderConfig(subloader) {
  const subloaderName = subloader.loader;
  if (subloaderName === 'postcss-loader') {
    subloader.options.postcssOptions = subloader.options.config;
    delete subloader.options.config;
  }
}

environment.loaders.keys().forEach(loaderName => {
  const loader = environment.loaders.get(loaderName);
  loader.use.forEach(hotfixPostcssLoaderConfig);
});

module.exports = environment;
