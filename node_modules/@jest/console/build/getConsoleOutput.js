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

function _jestMessageUtil() {
  const data = require('jest-message-util');

  _jestMessageUtil = function () {
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
var _default = (
  root,
  verbose,
  buffer, // TODO: make mandatory and take Config.ProjectConfig in 27
  config = {
    rootDir: root,
    testMatch: []
  },
  globalConfig
) => {
  const TITLE_INDENT = verbose ? '  ' : '    ';
  const CONSOLE_INDENT = TITLE_INDENT + '  ';
  const logEntries = buffer.reduce((output, {type, message, origin}) => {
    message = message
      .split(/\n/)
      .map(line => CONSOLE_INDENT + line)
      .join('\n');
    let typeMessage = 'console.' + type;
    let noStackTrace = true;
    let noCodeFrame = true;

    if (type === 'warn') {
      var _globalConfig$noStack;

      message = _chalk().default.yellow(message);
      typeMessage = _chalk().default.yellow(typeMessage);
      noStackTrace =
        (_globalConfig$noStack =
          globalConfig === null || globalConfig === void 0
            ? void 0
            : globalConfig.noStackTrace) !== null &&
        _globalConfig$noStack !== void 0
          ? _globalConfig$noStack
          : false;
      noCodeFrame = false;
    } else if (type === 'error') {
      var _globalConfig$noStack2;

      message = _chalk().default.red(message);
      typeMessage = _chalk().default.red(typeMessage);
      noStackTrace =
        (_globalConfig$noStack2 =
          globalConfig === null || globalConfig === void 0
            ? void 0
            : globalConfig.noStackTrace) !== null &&
        _globalConfig$noStack2 !== void 0
          ? _globalConfig$noStack2
          : false;
      noCodeFrame = false;
    }

    const options = {
      noCodeFrame,
      noStackTrace
    };
    const formattedStackTrace = (0, _jestMessageUtil().formatStackTrace)(
      origin,
      config,
      options
    );
    return (
      output +
      TITLE_INDENT +
      _chalk().default.dim(typeMessage) +
      '\n' +
      message.trimRight() +
      '\n' +
      _chalk().default.dim(formattedStackTrace.trimRight()) +
      '\n\n'
    );
  }, '');
  return logEntries.trimRight() + '\n';
};

exports.default = _default;
