'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _path() {
  const data = require('path');

  _path = function () {
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

var _constants = require('./constants');

var _getCacheDirectory = _interopRequireDefault(require('./getCacheDirectory'));

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
const NODE_MODULES_REGEXP = (0, _jestRegexUtil().replacePathSepForRegex)(
  _constants.NODE_MODULES
);
const defaultOptions = {
  automock: false,
  bail: 0,
  cache: true,
  cacheDirectory: (0, _getCacheDirectory.default)(),
  changedFilesWithAncestor: false,
  clearMocks: false,
  collectCoverage: false,
  coveragePathIgnorePatterns: [NODE_MODULES_REGEXP],
  coverageProvider: 'babel',
  coverageReporters: ['json', 'text', 'lcov', 'clover'],
  errorOnDeprecated: false,
  expand: false,
  forceCoverageMatch: [],
  globals: {},
  haste: {
    computeSha1: false,
    throwOnModuleCollision: false
  },
  injectGlobals: true,
  maxConcurrency: 5,
  maxWorkers: '50%',
  moduleDirectories: ['node_modules'],
  moduleFileExtensions: ['js', 'json', 'jsx', 'ts', 'tsx', 'node'],
  moduleNameMapper: {},
  modulePathIgnorePatterns: [],
  noStackTrace: false,
  notify: false,
  notifyMode: 'failure-change',
  prettierPath: 'prettier',
  resetMocks: false,
  resetModules: false,
  restoreMocks: false,
  roots: ['<rootDir>'],
  runTestsByPath: false,
  runner: 'jest-runner',
  setupFiles: [],
  setupFilesAfterEnv: [],
  skipFilter: false,
  slowTestThreshold: 5,
  snapshotSerializers: [],
  testEnvironment: 'jest-environment-jsdom',
  testEnvironmentOptions: {},
  testFailureExitCode: 1,
  testLocationInResults: false,
  testMatch: ['**/__tests__/**/*.[jt]s?(x)', '**/?(*.)+(spec|test).[tj]s?(x)'],
  testPathIgnorePatterns: [NODE_MODULES_REGEXP],
  testRegex: [],
  testRunner: 'jasmine2',
  testSequencer: '@jest/test-sequencer',
  testURL: 'http://localhost',
  timers: 'real',
  transformIgnorePatterns: [
    NODE_MODULES_REGEXP,
    `\\.pnp\\.[^\\${_path().sep}]+$`
  ],
  useStderr: false,
  watch: false,
  watchPathIgnorePatterns: [],
  watchman: true
};
var _default = defaultOptions;
exports.default = _default;
