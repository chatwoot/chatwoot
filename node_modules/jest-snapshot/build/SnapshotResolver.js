'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.buildSnapshotResolver = exports.isSnapshotPath = exports.DOT_EXTENSION = exports.EXTENSION = void 0;

var path = _interopRequireWildcard(require('path'));

var _chalk = _interopRequireDefault(require('chalk'));

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
const EXTENSION = 'snap';
exports.EXTENSION = EXTENSION;
const DOT_EXTENSION = '.' + EXTENSION;
exports.DOT_EXTENSION = DOT_EXTENSION;

const isSnapshotPath = path => path.endsWith(DOT_EXTENSION);

exports.isSnapshotPath = isSnapshotPath;
const cache = new Map();

const buildSnapshotResolver = config => {
  const key = config.rootDir;

  if (!cache.has(key)) {
    cache.set(key, createSnapshotResolver(config.snapshotResolver));
  }

  return cache.get(key);
};

exports.buildSnapshotResolver = buildSnapshotResolver;

function createSnapshotResolver(snapshotResolverPath) {
  return typeof snapshotResolverPath === 'string'
    ? createCustomSnapshotResolver(snapshotResolverPath)
    : createDefaultSnapshotResolver();
}

function createDefaultSnapshotResolver() {
  return {
    resolveSnapshotPath: testPath =>
      path.join(
        path.join(path.dirname(testPath), '__snapshots__'),
        path.basename(testPath) + DOT_EXTENSION
      ),
    resolveTestPath: snapshotPath =>
      path.resolve(
        path.dirname(snapshotPath),
        '..',
        path.basename(snapshotPath, DOT_EXTENSION)
      ),
    testPathForConsistencyCheck: path.posix.join(
      'consistency_check',
      '__tests__',
      'example.test.js'
    )
  };
}

function createCustomSnapshotResolver(snapshotResolverPath) {
  const custom = require(snapshotResolverPath);

  const keys = [
    ['resolveSnapshotPath', 'function'],
    ['resolveTestPath', 'function'],
    ['testPathForConsistencyCheck', 'string']
  ];
  keys.forEach(([propName, requiredType]) => {
    if (typeof custom[propName] !== requiredType) {
      throw new TypeError(mustImplement(propName, requiredType));
    }
  });
  const customResolver = {
    resolveSnapshotPath: testPath =>
      custom.resolveSnapshotPath(testPath, DOT_EXTENSION),
    resolveTestPath: snapshotPath =>
      custom.resolveTestPath(snapshotPath, DOT_EXTENSION),
    testPathForConsistencyCheck: custom.testPathForConsistencyCheck
  };
  verifyConsistentTransformations(customResolver);
  return customResolver;
}

function mustImplement(propName, requiredType) {
  return (
    _chalk.default.bold(
      `Custom snapshot resolver must implement a \`${propName}\` as a ${requiredType}.`
    ) +
    '\nDocumentation: https://facebook.github.io/jest/docs/en/configuration.html#snapshotResolver'
  );
}

function verifyConsistentTransformations(custom) {
  const resolvedSnapshotPath = custom.resolveSnapshotPath(
    custom.testPathForConsistencyCheck
  );
  const resolvedTestPath = custom.resolveTestPath(resolvedSnapshotPath);

  if (resolvedTestPath !== custom.testPathForConsistencyCheck) {
    throw new Error(
      _chalk.default.bold(
        `Custom snapshot resolver functions must transform paths consistently, i.e. expects resolveTestPath(resolveSnapshotPath('${custom.testPathForConsistencyCheck}')) === ${resolvedTestPath}`
      )
    );
  }
}
