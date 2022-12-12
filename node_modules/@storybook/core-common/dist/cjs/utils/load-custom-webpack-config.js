"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.loadCustomWebpackConfig = void 0;

var _path = _interopRequireDefault(require("path"));

var _interpretRequire = require("./interpret-require");

function _interopRequireDefault(obj) { return obj && obj.__esModule ? obj : { default: obj }; }

var webpackConfigs = ['webpack.config', 'webpackfile'];

var loadCustomWebpackConfig = function (configDir) {
  return (0, _interpretRequire.serverRequire)(webpackConfigs.map(function (configName) {
    return _path.default.resolve(configDir, configName);
  }));
};

exports.loadCustomWebpackConfig = loadCustomWebpackConfig;