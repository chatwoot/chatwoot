const { environment } = require('@rails/webpacker');
const { VueLoaderPlugin } = require('vue-loader');
const resolve = require('./resolve');
const vue = require('./loaders/vue');

// Implementation reference: https://chwt.app/webpacker-tailwind-jit
const sassLoader = environment.loaders.get('sass');
const sassLoaderConfig = sassLoader.use.find(
  element => element.loader === 'sass-loader'
);

const options = sassLoaderConfig.options;
options.implementation = require('sass');

const hotfixPostcssLoaderConfig = subloader => {
  const subloaderName = subloader.loader;
  if (subloaderName === 'postcss-loader') {
    subloader.options.postcssOptions = subloader.options.config;
    delete subloader.options.config;
  }
};

environment.loaders.keys().forEach(loaderName => {
  const loader = environment.loaders.get(loaderName);
  loader.use.forEach(hotfixPostcssLoaderConfig);
});

environment.plugins.prepend('VueLoaderPlugin', new VueLoaderPlugin());
environment.loaders.prepend('vue', vue);

environment.loaders.append('mjs-comptaibility-loader', {
  test: /\.mjs$/,
  include: /node_modules/,
  type: 'javascript/auto',
});

environment.loaders.append('opus-ogg', {
  test: /encoderWorker\.min\.js$/,
  loader: 'file-loader',
  options: {
    name: '[name].[ext]',
  },
});

environment.loaders.append('opus-wav', {
  test: /waveWorker\.min\.js$/,
  loader: 'file-loader',
  options: {
    name: '[name].[ext]',
  },
});

environment.loaders.append('audio', {
  test: /\.(mp3)(\?.*)?$/,
  loader: 'url-loader',
  query: {
    limit: 10000,
    name: 'audio/[name].[ext]',
  },
});

const preserveNameFor = ['sdk', 'worker'];

environment.config.merge({ resolve });
environment.config.set('output.filename', chunkData => {
  return preserveNameFor.includes(chunkData.chunk.name)
    ? 'js/[name].js'
    : 'js/[name]-[hash].js';
});

module.exports = environment;
