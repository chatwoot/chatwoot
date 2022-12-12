'use strict';

function _crypto() {
  const data = require('crypto');

  _crypto = function () {
    return data;
  };

  return data;
}

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

function fs() {
  const data = _interopRequireWildcard(require('graceful-fs'));

  fs = function () {
    return data;
  };

  return data;
}

function _core() {
  const data = require('@babel/core');

  _core = function () {
    return data;
  };

  return data;
}

var _loadBabelConfig = require('./loadBabelConfig');

function _chalk() {
  const data = _interopRequireDefault(require('chalk'));

  _chalk = function () {
    return data;
  };

  return data;
}

function _slash() {
  const data = _interopRequireDefault(require('slash'));

  _slash = function () {
    return data;
  };

  return data;
}

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

function _getRequireWildcardCache() {
  if (typeof WeakMap !== 'function') return null;
  var cache = new WeakMap();
  _getRequireWildcardCache = function () {
    return cache;
  };
  return cache;
}

function _interopRequireWildcard(obj) {
  if (obj && obj.__esModule) {
    return obj;
  }
  if (obj === null || (typeof obj !== 'object' && typeof obj !== 'function')) {
    return {default: obj};
  }
  var cache = _getRequireWildcardCache();
  if (cache && cache.has(obj)) {
    return cache.get(obj);
  }
  var newObj = {};
  var hasPropertyDescriptor =
    Object.defineProperty && Object.getOwnPropertyDescriptor;
  for (var key in obj) {
    if (Object.prototype.hasOwnProperty.call(obj, key)) {
      var desc = hasPropertyDescriptor
        ? Object.getOwnPropertyDescriptor(obj, key)
        : null;
      if (desc && (desc.get || desc.set)) {
        Object.defineProperty(newObj, key, desc);
      } else {
        newObj[key] = obj[key];
      }
    }
  }
  newObj.default = obj;
  if (cache) {
    cache.set(obj, newObj);
  }
  return newObj;
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
const THIS_FILE = fs().readFileSync(__filename);

const jestPresetPath = require.resolve('babel-preset-jest');

const babelIstanbulPlugin = require.resolve('babel-plugin-istanbul'); // Narrow down the types

const createTransformer = (inputOptions = {}) => {
  var _inputOptions$plugins, _inputOptions$presets;

  const options = {
    ...inputOptions,
    caller: {
      name: 'babel-jest',
      supportsDynamicImport: false,
      supportsStaticESM: false,
      ...inputOptions.caller
    },
    compact: false,
    plugins:
      (_inputOptions$plugins = inputOptions.plugins) !== null &&
      _inputOptions$plugins !== void 0
        ? _inputOptions$plugins
        : [],
    presets: ((_inputOptions$presets = inputOptions.presets) !== null &&
    _inputOptions$presets !== void 0
      ? _inputOptions$presets
      : []
    ).concat(jestPresetPath),
    sourceMaps: 'both'
  };

  function loadBabelConfig(cwd, filename, transformOptions) {
    var _transformOptions$sup, _transformOptions$sup2;

    // `cwd` first to allow incoming options to override it
    const babelConfig = (0, _loadBabelConfig.loadPartialConfig)({
      cwd,
      ...options,
      caller: {
        ...options.caller,
        supportsDynamicImport:
          (_transformOptions$sup =
            transformOptions === null || transformOptions === void 0
              ? void 0
              : transformOptions.supportsDynamicImport) !== null &&
          _transformOptions$sup !== void 0
            ? _transformOptions$sup
            : options.caller.supportsDynamicImport,
        supportsStaticESM:
          (_transformOptions$sup2 =
            transformOptions === null || transformOptions === void 0
              ? void 0
              : transformOptions.supportsStaticESM) !== null &&
          _transformOptions$sup2 !== void 0
            ? _transformOptions$sup2
            : options.caller.supportsStaticESM
      },
      filename
    });

    if (!babelConfig) {
      throw new Error(
        `babel-jest: Babel ignores ${_chalk().default.bold(
          (0, _slash().default)(path().relative(cwd, filename))
        )} - make sure to include the file in Jest's ${_chalk().default.bold(
          'transformIgnorePatterns'
        )} as well.`
      );
    }

    return babelConfig;
  }

  return {
    canInstrument: true,

    getCacheKey(fileData, filename, configString, cacheKeyOptions) {
      const {config, instrument, rootDir} = cacheKeyOptions;
      const babelOptions = loadBabelConfig(
        config.cwd,
        filename,
        cacheKeyOptions
      );
      const configPath = [
        babelOptions.config || '',
        babelOptions.babelrc || ''
      ];
      return (0, _crypto().createHash)('md5')
        .update(THIS_FILE)
        .update('\0', 'utf8')
        .update(JSON.stringify(babelOptions.options))
        .update('\0', 'utf8')
        .update(fileData)
        .update('\0', 'utf8')
        .update(path().relative(rootDir, filename))
        .update('\0', 'utf8')
        .update(configString)
        .update('\0', 'utf8')
        .update(configPath.join(''))
        .update('\0', 'utf8')
        .update(instrument ? 'instrument' : '')
        .update('\0', 'utf8')
        .update(process.env.NODE_ENV || '')
        .update('\0', 'utf8')
        .update(process.env.BABEL_ENV || '')
        .digest('hex');
    },

    process(src, filename, config, transformOptions) {
      const babelOptions = {
        ...loadBabelConfig(config.cwd, filename, transformOptions).options
      };

      if (
        transformOptions === null || transformOptions === void 0
          ? void 0
          : transformOptions.instrument
      ) {
        babelOptions.auxiliaryCommentBefore = ' istanbul ignore next '; // Copied from jest-runtime transform.js

        babelOptions.plugins = (babelOptions.plugins || []).concat([
          [
            babelIstanbulPlugin,
            {
              // files outside `cwd` will not be instrumented
              cwd: config.rootDir,
              exclude: []
            }
          ]
        ]);
      }

      const transformResult = (0, _core().transformSync)(src, babelOptions);

      if (transformResult) {
        const {code, map} = transformResult;

        if (typeof code === 'string') {
          return {
            code,
            map
          };
        }
      }

      return src;
    }
  };
};

const transformer = {
  ...createTransformer(),
  // Assigned here so only the exported transformer has `createTransformer`,
  // instead of all created transformers by the function
  createTransformer
};
module.exports = transformer;
