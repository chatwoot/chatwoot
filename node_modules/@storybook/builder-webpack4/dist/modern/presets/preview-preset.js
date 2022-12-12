import "core-js/modules/es.promise.js";
import webpackConfig from '../preview/iframe-webpack.config';
export var webpack = async function (_, options) {
  return webpackConfig(options);
};
export var entries = async function (_, options) {
  var result = [];
  result = result.concat(await options.presets.apply('previewEntries', [], options));

  if (options.configType === 'DEVELOPMENT') {
    // Suppress informational messages when --quiet is specified. webpack-hot-middleware's quiet
    // parameter would also suppress warnings.
    result = result.concat(`${require.resolve('webpack-hot-middleware/client')}?reload=true&quiet=false&noInfo=${options.quiet}`);
  }

  return result;
};