'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.getSequencer = exports.isJSONString = exports.getRunner = exports.getWatchPlugin = exports.getTestEnvironment = exports.resolveWithPrefix = exports._replaceRootDirTags = exports.replaceRootDirInPath = exports.escapeGlobCharacters = exports.resolve = exports.DOCUMENTATION_NOTE = exports.BULLET = void 0;

function path() {
  const data = _interopRequireWildcard(require('path'));

  path = function () {
    return data;
  };

  return data;
}

function _chalk() {
  const data = _interopRequireDefault(require('chalk'));

  _chalk = function () {
    return data;
  };

  return data;
}

function _jestResolve() {
  const data = _interopRequireDefault(require('jest-resolve'));

  _jestResolve = function () {
    return data;
  };

  return data;
}

function _jestValidate() {
  const data = require('jest-validate');

  _jestValidate = function () {
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
const BULLET = _chalk().default.bold('\u25cf ');

exports.BULLET = BULLET;
const DOCUMENTATION_NOTE = `  ${_chalk().default.bold(
  'Configuration Documentation:'
)}
  https://jestjs.io/docs/configuration.html
`;
exports.DOCUMENTATION_NOTE = DOCUMENTATION_NOTE;

const createValidationError = message =>
  new (_jestValidate().ValidationError)(
    `${BULLET}Validation Error`,
    message,
    DOCUMENTATION_NOTE
  );

const resolve = (resolver, {key, filePath, rootDir, optional}) => {
  const module = _jestResolve().default.findNodeModule(
    replaceRootDirInPath(rootDir, filePath),
    {
      basedir: rootDir,
      resolver: resolver || undefined
    }
  );

  if (!module && !optional) {
    throw createValidationError(`  Module ${_chalk().default.bold(
      filePath
    )} in the ${_chalk().default.bold(key)} option was not found.
         ${_chalk().default.bold('<rootDir>')} is: ${rootDir}`);
  } /// can cast as string since nulls will be thrown

  return module;
};

exports.resolve = resolve;

const escapeGlobCharacters = path => path.replace(/([()*{}\[\]!?\\])/g, '\\$1');

exports.escapeGlobCharacters = escapeGlobCharacters;

const replaceRootDirInPath = (rootDir, filePath) => {
  if (!/^<rootDir>/.test(filePath)) {
    return filePath;
  }

  return path().resolve(
    rootDir,
    path().normalize('./' + filePath.substr('<rootDir>'.length))
  );
};

exports.replaceRootDirInPath = replaceRootDirInPath;

const _replaceRootDirInObject = (rootDir, config) => {
  const newConfig = {};

  for (const configKey in config) {
    newConfig[configKey] =
      configKey === 'rootDir'
        ? config[configKey]
        : _replaceRootDirTags(rootDir, config[configKey]);
  }

  return newConfig;
};

const _replaceRootDirTags = (rootDir, config) => {
  if (config == null) {
    return config;
  }

  switch (typeof config) {
    case 'object':
      if (Array.isArray(config)) {
        /// can be string[] or {}[]
        return config.map(item => _replaceRootDirTags(rootDir, item));
      }

      if (config instanceof RegExp) {
        return config;
      }

      return _replaceRootDirInObject(rootDir, config);

    case 'string':
      return replaceRootDirInPath(rootDir, config);
  }

  return config;
};

exports._replaceRootDirTags = _replaceRootDirTags;

const resolveWithPrefix = (
  resolver,
  {filePath, humanOptionName, optionName, prefix, rootDir}
) => {
  const fileName = replaceRootDirInPath(rootDir, filePath);

  let module = _jestResolve().default.findNodeModule(`${prefix}${fileName}`, {
    basedir: rootDir,
    resolver: resolver || undefined
  });

  if (module) {
    return module;
  }

  try {
    return require.resolve(`${prefix}${fileName}`);
  } catch {}

  module = _jestResolve().default.findNodeModule(fileName, {
    basedir: rootDir,
    resolver: resolver || undefined
  });

  if (module) {
    return module;
  }

  try {
    return require.resolve(fileName);
  } catch {}

  throw createValidationError(
    `  ${humanOptionName} ${_chalk().default.bold(
      fileName
    )} cannot be found. Make sure the ${_chalk().default.bold(
      optionName
    )} configuration option points to an existing node module.`
  );
};
/**
 * Finds the test environment to use:
 *
 * 1. looks for jest-environment-<name> relative to project.
 * 1. looks for jest-environment-<name> relative to Jest.
 * 1. looks for <name> relative to project.
 * 1. looks for <name> relative to Jest.
 */

exports.resolveWithPrefix = resolveWithPrefix;

const getTestEnvironment = ({rootDir, testEnvironment: filePath}) =>
  resolveWithPrefix(undefined, {
    filePath,
    humanOptionName: 'Test environment',
    optionName: 'testEnvironment',
    prefix: 'jest-environment-',
    rootDir
  });
/**
 * Finds the watch plugins to use:
 *
 * 1. looks for jest-watch-<name> relative to project.
 * 1. looks for jest-watch-<name> relative to Jest.
 * 1. looks for <name> relative to project.
 * 1. looks for <name> relative to Jest.
 */

exports.getTestEnvironment = getTestEnvironment;

const getWatchPlugin = (resolver, {filePath, rootDir}) =>
  resolveWithPrefix(resolver, {
    filePath,
    humanOptionName: 'Watch plugin',
    optionName: 'watchPlugins',
    prefix: 'jest-watch-',
    rootDir
  });
/**
 * Finds the runner to use:
 *
 * 1. looks for jest-runner-<name> relative to project.
 * 1. looks for jest-runner-<name> relative to Jest.
 * 1. looks for <name> relative to project.
 * 1. looks for <name> relative to Jest.
 */

exports.getWatchPlugin = getWatchPlugin;

const getRunner = (resolver, {filePath, rootDir}) =>
  resolveWithPrefix(resolver, {
    filePath,
    humanOptionName: 'Jest Runner',
    optionName: 'runner',
    prefix: 'jest-runner-',
    rootDir
  });

exports.getRunner = getRunner;

// newtype
const isJSONString = text =>
  text != null &&
  typeof text === 'string' &&
  text.startsWith('{') &&
  text.endsWith('}');

exports.isJSONString = isJSONString;

const getSequencer = (resolver, {filePath, rootDir}) =>
  resolveWithPrefix(resolver, {
    filePath,
    humanOptionName: 'Jest Sequencer',
    optionName: 'testSequencer',
    prefix: 'jest-sequencer-',
    rootDir
  });

exports.getSequencer = getSequencer;
