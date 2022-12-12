"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.createBabelLoader = void 0;

var _coreCommon = require("@storybook/core-common");

var _useBaseTsSupport = require("./useBaseTsSupport");

var createBabelLoader = function (options, framework) {
  return {
    test: (0, _useBaseTsSupport.useBaseTsSupport)(framework) ? /\.(mjs|tsx?|jsx?)$/ : /\.(mjs|jsx?)$/,
    use: [{
      loader: require.resolve('babel-loader'),
      options: options
    }],
    include: [(0, _coreCommon.getProjectRoot)()],
    exclude: /node_modules/
  };
};

exports.createBabelLoader = createBabelLoader;