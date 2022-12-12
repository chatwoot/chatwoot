"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.webpack = webpack;
exports.webpackVersion = exports.webpackInstance = void 0;

require("core-js/modules/es.promise.js");

var webpackReal = _interopRequireWildcard(require("webpack"));

var _nodeLogger = require("@storybook/node-logger");

var _coreCommon = require("@storybook/core-common");

var _baseWebpack = require("../preview/base-webpack.config");

function _getRequireWildcardCache(nodeInterop) { if (typeof WeakMap !== "function") return null; var cacheBabelInterop = new WeakMap(); var cacheNodeInterop = new WeakMap(); return (_getRequireWildcardCache = function (nodeInterop) { return nodeInterop ? cacheNodeInterop : cacheBabelInterop; })(nodeInterop); }

function _interopRequireWildcard(obj, nodeInterop) { if (!nodeInterop && obj && obj.__esModule) { return obj; } if (obj === null || typeof obj !== "object" && typeof obj !== "function") { return { default: obj }; } var cache = _getRequireWildcardCache(nodeInterop); if (cache && cache.has(obj)) { return cache.get(obj); } var newObj = {}; var hasPropertyDescriptor = Object.defineProperty && Object.getOwnPropertyDescriptor; for (var key in obj) { if (key !== "default" && Object.prototype.hasOwnProperty.call(obj, key)) { var desc = hasPropertyDescriptor ? Object.getOwnPropertyDescriptor(obj, key) : null; if (desc && (desc.get || desc.set)) { Object.defineProperty(newObj, key, desc); } else { newObj[key] = obj[key]; } } } newObj.default = obj; if (cache) { cache.set(obj, newObj); } return newObj; }

async function webpack(config, options) {
  // @ts-ignore
  var configDir = options.configDir,
      configType = options.configType,
      presets = options.presets,
      webpackConfig = options.webpackConfig;
  var coreOptions = await presets.apply('core');
  var defaultConfig = config;

  if (!(coreOptions !== null && coreOptions !== void 0 && coreOptions.disableWebpackDefaults)) {
    defaultConfig = await (0, _baseWebpack.createDefaultWebpackConfig)(config, options);
  }

  var finalDefaultConfig = await presets.apply('webpackFinal', defaultConfig, options); // through standalone webpackConfig option

  if (webpackConfig) {
    return webpackConfig(finalDefaultConfig);
  } // Check whether user has a custom webpack config file and
  // return the (extended) base configuration if it's not available.


  var customConfig = (0, _coreCommon.loadCustomWebpackConfig)(configDir);

  if (typeof customConfig === 'function') {
    _nodeLogger.logger.info('=> Loading custom Webpack config (full-control mode).');

    return customConfig({
      config: finalDefaultConfig,
      mode: configType
    });
  }

  _nodeLogger.logger.info('=> Using default Webpack4 setup');

  return finalDefaultConfig;
}

var webpackInstance = async function () {
  return webpackReal;
};

exports.webpackInstance = webpackInstance;

var webpackVersion = async function () {
  return '4';
};

exports.webpackVersion = webpackVersion;