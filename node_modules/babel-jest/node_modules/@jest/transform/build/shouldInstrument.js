'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = shouldInstrument;

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

function _jestRegexUtil() {
  const data = require('jest-regex-util');

  _jestRegexUtil = function () {
    return data;
  };

  return data;
}

function _jestUtil() {
  const data = require('jest-util');

  _jestUtil = function () {
    return data;
  };

  return data;
}

function _micromatch() {
  const data = _interopRequireDefault(require('micromatch'));

  _micromatch = function () {
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
const MOCKS_PATTERN = new RegExp(
  (0, _jestRegexUtil().escapePathForRegex)(
    path().sep + '__mocks__' + path().sep
  )
);

function shouldInstrument(filename, options, config) {
  if (!options.collectCoverage) {
    return false;
  }

  if (
    config.forceCoverageMatch.length &&
    _micromatch().default.any(filename, config.forceCoverageMatch)
  ) {
    return true;
  }

  if (
    !config.testPathIgnorePatterns.some(pattern => !!filename.match(pattern))
  ) {
    if (config.testRegex.some(regex => new RegExp(regex).test(filename))) {
      return false;
    }

    if (
      (0, _micromatch().default)(
        [(0, _jestUtil().replacePathSepForGlob)(filename)],
        config.testMatch
      ).length
    ) {
      return false;
    }
  }

  if (
    // This configuration field contains an object in the form of:
    // {'path/to/file.js': true}
    options.collectCoverageOnlyFrom &&
    !options.collectCoverageOnlyFrom[filename]
  ) {
    return false;
  }

  if (
    // still cover if `only` is specified
    !options.collectCoverageOnlyFrom &&
    options.collectCoverageFrom.length &&
    (0, _micromatch().default)(
      [
        (0, _jestUtil().replacePathSepForGlob)(
          path().relative(config.rootDir, filename)
        )
      ],
      options.collectCoverageFrom
    ).length === 0
  ) {
    return false;
  }

  if (
    config.coveragePathIgnorePatterns.some(pattern => !!filename.match(pattern))
  ) {
    return false;
  }

  if (config.globalSetup === filename) {
    return false;
  }

  if (config.globalTeardown === filename) {
    return false;
  }

  if (config.setupFiles.includes(filename)) {
    return false;
  }

  if (config.setupFilesAfterEnv.includes(filename)) {
    return false;
  }

  if (MOCKS_PATTERN.test(filename)) {
    return false;
  }

  if (options.changedFiles && !options.changedFiles.has(filename)) {
    if (!options.sourcesRelatedToTestsInChangedFiles) {
      return false;
    }

    if (!options.sourcesRelatedToTestsInChangedFiles.has(filename)) {
      return false;
    }
  }

  return true;
}
