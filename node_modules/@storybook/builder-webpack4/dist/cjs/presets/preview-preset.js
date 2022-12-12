"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.webpack = exports.entries = void 0;

require("core-js/modules/es.promise.js");

var _iframeWebpack = _interopRequireDefault(require("../preview/iframe-webpack.config"));

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var webpack = async function (_, options) {
  return (0, _iframeWebpack.default)(options);
};

exports.webpack = webpack;

var entries = async function (_, options) {
  var result = [];
  result = result.concat(await options.presets.apply('previewEntries', [], options));

  if (options.configType === 'DEVELOPMENT') {
    // Suppress informational messages when --quiet is specified. webpack-hot-middleware's quiet
    // parameter would also suppress warnings.
    result = result.concat(`${require.resolve('webpack-hot-middleware/client')}?reload=true&quiet=false&noInfo=${options.quiet}`);
  }

  return result;
};

exports.entries = entries;