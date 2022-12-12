'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.JEST_CONFIG_EXT_ORDER = exports.JEST_CONFIG_EXT_JSON = exports.JEST_CONFIG_EXT_TS = exports.JEST_CONFIG_EXT_JS = exports.JEST_CONFIG_EXT_MJS = exports.JEST_CONFIG_EXT_CJS = exports.JEST_CONFIG_BASE_NAME = exports.PACKAGE_JSON = exports.DEFAULT_REPORTER_LABEL = exports.DEFAULT_JS_PATTERN = exports.NODE_MODULES = void 0;

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
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
const NODE_MODULES = path().sep + 'node_modules' + path().sep;
exports.NODE_MODULES = NODE_MODULES;
const DEFAULT_JS_PATTERN = '\\.[jt]sx?$';
exports.DEFAULT_JS_PATTERN = DEFAULT_JS_PATTERN;
const DEFAULT_REPORTER_LABEL = 'default';
exports.DEFAULT_REPORTER_LABEL = DEFAULT_REPORTER_LABEL;
const PACKAGE_JSON = 'package.json';
exports.PACKAGE_JSON = PACKAGE_JSON;
const JEST_CONFIG_BASE_NAME = 'jest.config';
exports.JEST_CONFIG_BASE_NAME = JEST_CONFIG_BASE_NAME;
const JEST_CONFIG_EXT_CJS = '.cjs';
exports.JEST_CONFIG_EXT_CJS = JEST_CONFIG_EXT_CJS;
const JEST_CONFIG_EXT_MJS = '.mjs';
exports.JEST_CONFIG_EXT_MJS = JEST_CONFIG_EXT_MJS;
const JEST_CONFIG_EXT_JS = '.js';
exports.JEST_CONFIG_EXT_JS = JEST_CONFIG_EXT_JS;
const JEST_CONFIG_EXT_TS = '.ts';
exports.JEST_CONFIG_EXT_TS = JEST_CONFIG_EXT_TS;
const JEST_CONFIG_EXT_JSON = '.json';
exports.JEST_CONFIG_EXT_JSON = JEST_CONFIG_EXT_JSON;
const JEST_CONFIG_EXT_ORDER = Object.freeze([
  JEST_CONFIG_EXT_JS,
  JEST_CONFIG_EXT_TS,
  JEST_CONFIG_EXT_MJS,
  JEST_CONFIG_EXT_CJS,
  JEST_CONFIG_EXT_JSON
]);
exports.JEST_CONFIG_EXT_ORDER = JEST_CONFIG_EXT_ORDER;
