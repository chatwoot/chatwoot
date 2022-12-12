'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.clearCachedLookups = clearCachedLookups;
exports.default = cachedShouldLoadAsEsm;

function _path() {
  const data = require('path');

  _path = function () {
    return data;
  };

  return data;
}

function _vm() {
  const data = require('vm');

  _vm = function () {
    return data;
  };

  return data;
}

function _readPkgUp() {
  const data = _interopRequireDefault(require('read-pkg-up'));

  _readPkgUp = function () {
    return data;
  };

  return data;
}

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
// @ts-expect-error: experimental, not added to the types
const runtimeSupportsVmModules = typeof _vm().SyntheticModule === 'function';
const cachedFileLookups = new Map();
const cachedDirLookups = new Map();

function clearCachedLookups() {
  cachedFileLookups.clear();
  cachedDirLookups.clear();
}

function cachedShouldLoadAsEsm(path) {
  let cachedLookup = cachedFileLookups.get(path);

  if (cachedLookup === undefined) {
    cachedLookup = shouldLoadAsEsm(path);
    cachedFileLookups.set(path, cachedLookup);
  }

  return cachedLookup;
} // this is a bad version of what https://github.com/nodejs/modules/issues/393 would provide

function shouldLoadAsEsm(path) {
  if (!runtimeSupportsVmModules) {
    return false;
  }

  const extension = (0, _path().extname)(path);

  if (extension === '.mjs') {
    return true;
  }

  if (extension === '.cjs') {
    return false;
  } // this isn't correct - we might wanna load any file as a module (using synthetic module)
  // do we need an option to Jest so people can opt in to ESM for non-js?

  if (extension !== '.js') {
    return false;
  }

  const cwd = (0, _path().dirname)(path);
  let cachedLookup = cachedDirLookups.get(cwd);

  if (cachedLookup === undefined) {
    cachedLookup = cachedPkgCheck(cwd);
    cachedFileLookups.set(cwd, cachedLookup);
  }

  return cachedLookup;
}

function cachedPkgCheck(cwd) {
  // TODO: can we cache lookups somehow?
  const pkg = _readPkgUp().default.sync({
    cwd,
    normalize: false
  });

  if (!pkg) {
    return false;
  }

  return pkg.packageJson.type === 'module';
}
