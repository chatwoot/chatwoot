'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _chalk() {
  const data = _interopRequireDefault(require('chalk'));

  _chalk = function () {
    return data;
  };

  return data;
}

function _terminalLink() {
  const data = _interopRequireDefault(require('terminal-link'));

  _terminalLink = function () {
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

var _utils = require('./utils');

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
const LONG_TEST_COLOR = _chalk().default.reset.bold.bgRed; // Explicitly reset for these messages since they can get written out in the
// middle of error logging

const FAIL_TEXT = 'FAIL';
const PASS_TEXT = 'PASS';
const FAIL = _chalk().default.supportsColor
  ? _chalk().default.reset.inverse.bold.red(` ${FAIL_TEXT} `)
  : FAIL_TEXT;
const PASS = _chalk().default.supportsColor
  ? _chalk().default.reset.inverse.bold.green(` ${PASS_TEXT} `)
  : PASS_TEXT;

var _default = (result, globalConfig, projectConfig) => {
  var _result$perfStats;

  const testPath = result.testFilePath;
  const formattedTestPath = (0, _utils.formatTestPath)(
    projectConfig ? projectConfig : globalConfig,
    testPath
  );
  const fileLink = (0, _terminalLink().default)(
    formattedTestPath,
    `file://${testPath}`,
    {
      fallback: () => formattedTestPath
    }
  );
  const status =
    result.numFailingTests > 0 || result.testExecError ? FAIL : PASS;
  const testDetail = [];

  if (
    (_result$perfStats = result.perfStats) === null ||
    _result$perfStats === void 0
      ? void 0
      : _result$perfStats.slow
  ) {
    const runTime = result.perfStats.runtime / 1000;
    testDetail.push(LONG_TEST_COLOR((0, _jestUtil().formatTime)(runTime, 0)));
  }

  if (result.memoryUsage) {
    const toMB = bytes => Math.floor(bytes / 1024 / 1024);

    testDetail.push(`${toMB(result.memoryUsage)} MB heap size`);
  }

  const projectDisplayName =
    projectConfig && projectConfig.displayName
      ? (0, _utils.printDisplayName)(projectConfig) + ' '
      : '';
  return (
    `${status} ${projectDisplayName}${fileLink}` +
    (testDetail.length ? ` (${testDetail.join(', ')})` : '')
  );
};

exports.default = _default;
