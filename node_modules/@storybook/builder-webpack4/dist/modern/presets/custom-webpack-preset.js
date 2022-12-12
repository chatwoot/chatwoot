import "core-js/modules/es.promise.js";
import * as webpackReal from 'webpack';
import { logger } from '@storybook/node-logger';
import { loadCustomWebpackConfig } from '@storybook/core-common';
import { createDefaultWebpackConfig } from '../preview/base-webpack.config';
export async function webpack(config, options) {
  // @ts-ignore
  var configDir = options.configDir,
      configType = options.configType,
      presets = options.presets,
      webpackConfig = options.webpackConfig;
  var coreOptions = await presets.apply('core');
  var defaultConfig = config;

  if (!(coreOptions !== null && coreOptions !== void 0 && coreOptions.disableWebpackDefaults)) {
    defaultConfig = await createDefaultWebpackConfig(config, options);
  }

  var finalDefaultConfig = await presets.apply('webpackFinal', defaultConfig, options); // through standalone webpackConfig option

  if (webpackConfig) {
    return webpackConfig(finalDefaultConfig);
  } // Check whether user has a custom webpack config file and
  // return the (extended) base configuration if it's not available.


  var customConfig = loadCustomWebpackConfig(configDir);

  if (typeof customConfig === 'function') {
    logger.info('=> Loading custom Webpack config (full-control mode).');
    return customConfig({
      config: finalDefaultConfig,
      mode: configType
    });
  }

  logger.info('=> Using default Webpack4 setup');
  return finalDefaultConfig;
}
export var webpackInstance = async function () {
  return webpackReal;
};
export var webpackVersion = async function () {
  return '4';
};