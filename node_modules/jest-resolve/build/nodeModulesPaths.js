'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = nodeModulesPaths;

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
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
 *
 * Adapted from: https://github.com/substack/node-resolve
 */
function nodeModulesPaths(basedir, options) {
  const modules =
    options && options.moduleDirectory
      ? Array.from(options.moduleDirectory)
      : ['node_modules']; // ensure that `basedir` is an absolute path at this point,
  // resolving against the process' current working directory

  const basedirAbs = path().resolve(basedir);
  let prefix = '/';

  if (/^([A-Za-z]:)/.test(basedirAbs)) {
    prefix = '';
  } else if (/^\\\\/.test(basedirAbs)) {
    prefix = '\\\\';
  } // The node resolution algorithm (as implemented by NodeJS and TypeScript)
  // traverses parents of the physical path, not the symlinked path

  let physicalBasedir;

  try {
    physicalBasedir = (0, _jestUtil().tryRealpath)(basedirAbs);
  } catch {
    // realpath can throw, e.g. on mapped drives
    physicalBasedir = basedirAbs;
  }

  const paths = [physicalBasedir];
  let parsed = path().parse(physicalBasedir);

  while (parsed.dir !== paths[paths.length - 1]) {
    paths.push(parsed.dir);
    parsed = path().parse(parsed.dir);
  }

  const dirs = paths
    .reduce(
      (dirs, aPath) =>
        dirs.concat(
          modules.map(moduleDir =>
            path().isAbsolute(moduleDir)
              ? aPath === basedirAbs
                ? moduleDir
                : ''
              : path().join(prefix, aPath, moduleDir)
          )
        ),
      []
    )
    .filter(dir => dir !== '');
  return options.paths ? dirs.concat(options.paths) : dirs;
}
