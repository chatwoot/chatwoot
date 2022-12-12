'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

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

var _constants = require('./constants');

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
const isFile = filePath =>
  fs().existsSync(filePath) && !fs().lstatSync(filePath).isDirectory();

const getConfigFilename = ext => _constants.JEST_CONFIG_BASE_NAME + ext;

var _default = (pathToResolve, cwd) => {
  if (!path().isAbsolute(cwd)) {
    throw new Error(`"cwd" must be an absolute path. cwd: ${cwd}`);
  }

  const absolutePath = path().isAbsolute(pathToResolve)
    ? pathToResolve
    : path().resolve(cwd, pathToResolve);

  if (isFile(absolutePath)) {
    return absolutePath;
  } // This is a guard against passing non existing path as a project/config,
  // that will otherwise result in a very confusing situation.
  // e.g.
  // With a directory structure like this:
  //   my_project/
  //     packcage.json
  //
  // Passing a `my_project/some_directory_that_doesnt_exist` as a project
  // name will resolve into a (possibly empty) `my_project/package.json` and
  // try to run all tests it finds under `my_project` directory.

  if (!fs().existsSync(absolutePath)) {
    throw new Error(
      `Can't find a root directory while resolving a config file path.\n` +
        `Provided path to resolve: ${pathToResolve}\n` +
        `cwd: ${cwd}`
    );
  }

  return resolveConfigPathByTraversing(absolutePath, pathToResolve, cwd);
};

exports.default = _default;

const resolveConfigPathByTraversing = (pathToResolve, initialPath, cwd) => {
  const jestConfig = _constants.JEST_CONFIG_EXT_ORDER.map(ext =>
    path().resolve(pathToResolve, getConfigFilename(ext))
  ).find(isFile);

  if (jestConfig) {
    return jestConfig;
  }

  const packageJson = path().resolve(pathToResolve, _constants.PACKAGE_JSON);

  if (isFile(packageJson)) {
    return packageJson;
  } // This is the system root.
  // We tried everything, config is nowhere to be found ¯\_(ツ)_/¯

  if (pathToResolve === path().dirname(pathToResolve)) {
    throw new Error(makeResolutionErrorMessage(initialPath, cwd));
  } // go up a level and try it again

  return resolveConfigPathByTraversing(
    path().dirname(pathToResolve),
    initialPath,
    cwd
  );
};

const makeResolutionErrorMessage = (initialPath, cwd) =>
  'Could not find a config file based on provided values:\n' +
  `path: "${initialPath}"\n` +
  `cwd: "${cwd}"\n` +
  'Config paths must be specified by either a direct path to a config\n' +
  'file, or a path to a directory. If directory is given, Jest will try to\n' +
  `traverse directory tree up, until it finds one of those files in exact order: ${_constants.JEST_CONFIG_EXT_ORDER.map(
    ext => `"${getConfigFilename(ext)}"`
  ).join(' or ')}.`;
