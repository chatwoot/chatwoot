import path from 'path';
import { serverRequire } from './interpret-require';
var webpackConfigs = ['webpack.config', 'webpackfile'];
export var loadCustomWebpackConfig = function (configDir) {
  return serverRequire(webpackConfigs.map(function (configName) {
    return path.resolve(configDir, configName);
  }));
};