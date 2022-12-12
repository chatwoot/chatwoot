"use strict";

Object.defineProperty(exports, "__esModule", {
  value: true
});
exports.es6Transpiler = void 0;

var _babel = require("./babel");

var _getStorybookBabelCon = (0, _babel.getStorybookBabelConfig)(),
    plugins = _getStorybookBabelCon.plugins;

var nodeModulesThatNeedToBeParsedBecauseTheyExposeES6 = ['@storybook[\\\\/]expect', '@storybook[\\\\/]node_logger', '@testing-library[\\\\/]dom', '@testing-library[\\\\/]user-event', 'acorn-jsx', 'ansi-align', 'ansi-colors', 'ansi-escapes', 'ansi-regex', 'ansi-styles', 'better-opn', 'boxen', 'chalk', 'color-convert', 'commander', 'find-cache-dir', 'find-up', 'fs-extra', 'highlight.js', 'jest-mock', 'json5', 'node-fetch', 'pkg-dir', 'prettier', 'pretty-format', 'react-router', 'react-router-dom', 'resolve-from', 'semver', 'slash', 'strip-ansi'].map(function (n) {
  return new RegExp(`[\\\\/]node_modules[\\\\/]${n}`);
});

var es6Transpiler = function () {
  var include = function (input) {
    return !!nodeModulesThatNeedToBeParsedBecauseTheyExposeES6.find(function (p) {
      return input.match(p);
    });
  };

  return {
    test: /\.js$/,
    use: [{
      loader: require.resolve('babel-loader'),
      options: {
        sourceType: 'unambiguous',
        presets: [[require.resolve('@babel/preset-env'), {
          shippedProposals: true,
          modules: false,
          loose: true,
          targets: 'defaults'
        }], require.resolve('@babel/preset-react')],
        plugins: plugins
      }
    }],
    include: include
  };
};

exports.es6Transpiler = es6Transpiler;