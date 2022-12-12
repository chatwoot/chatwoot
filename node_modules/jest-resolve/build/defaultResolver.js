'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = defaultResolver;
exports.clearDefaultResolverCache = clearDefaultResolverCache;

function fs() {
  const data = _interopRequireWildcard(require('graceful-fs'));

  fs = function () {
    return data;
  };

  return data;
}

function _jestPnpResolver() {
  const data = _interopRequireDefault(require('jest-pnp-resolver'));

  _jestPnpResolver = function () {
    return data;
  };

  return data;
}

function _resolve() {
  const data = require('resolve');

  _resolve = function () {
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
function defaultResolver(path, options) {
  if (process.versions.pnp && options.allowPnp !== false) {
    return (0, _jestPnpResolver().default)(path, options);
  }

  const result = (0, _resolve().sync)(path, {
    basedir: options.basedir,
    extensions: options.extensions,
    isDirectory,
    isFile,
    moduleDirectory: options.moduleDirectory,
    packageFilter: options.packageFilter,
    paths: options.paths,
    preserveSymlinks: false,
    realpathSync
  }); // Dereference symlinks to ensure we don't create a separate
  // module instance depending on how it was referenced.

  return realpathSync(result);
}

function clearDefaultResolverCache() {
  checkedPaths.clear();
  checkedRealpathPaths.clear();
}

var IPathType;

(function (IPathType) {
  IPathType[(IPathType['FILE'] = 1)] = 'FILE';
  IPathType[(IPathType['DIRECTORY'] = 2)] = 'DIRECTORY';
  IPathType[(IPathType['OTHER'] = 3)] = 'OTHER';
})(IPathType || (IPathType = {}));

const checkedPaths = new Map();

function statSyncCached(path) {
  const result = checkedPaths.get(path);

  if (result !== undefined) {
    return result;
  }

  let stat;

  try {
    stat = fs().statSync(path);
  } catch (e) {
    if (!(e && (e.code === 'ENOENT' || e.code === 'ENOTDIR'))) {
      throw e;
    }
  }

  if (stat) {
    if (stat.isFile() || stat.isFIFO()) {
      checkedPaths.set(path, IPathType.FILE);
      return IPathType.FILE;
    } else if (stat.isDirectory()) {
      checkedPaths.set(path, IPathType.DIRECTORY);
      return IPathType.DIRECTORY;
    }
  }

  checkedPaths.set(path, IPathType.OTHER);
  return IPathType.OTHER;
}

const checkedRealpathPaths = new Map();

function realpathCached(path) {
  let result = checkedRealpathPaths.get(path);

  if (result !== undefined) {
    return result;
  }

  result = (0, _jestUtil().tryRealpath)(path);
  checkedRealpathPaths.set(path, result);

  if (path !== result) {
    // also cache the result in case it's ever referenced directly - no reason to `realpath` that as well
    checkedRealpathPaths.set(result, result);
  }

  return result;
}
/*
 * helper functions
 */

function isFile(file) {
  return statSyncCached(file) === IPathType.FILE;
}

function isDirectory(dir) {
  return statSyncCached(dir) === IPathType.DIRECTORY;
}

function realpathSync(file) {
  return realpathCached(file);
}
