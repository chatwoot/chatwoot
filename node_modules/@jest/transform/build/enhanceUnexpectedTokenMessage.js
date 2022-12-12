'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = handlePotentialSyntaxError;
exports.enhanceUnexpectedTokenMessage = enhanceUnexpectedTokenMessage;

function _chalk() {
  const data = _interopRequireDefault(require('chalk'));

  _chalk = function () {
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
const DOT = ' \u2022 ';

function handlePotentialSyntaxError(e) {
  if (e.codeFrame) {
    e.stack = e.message + '\n' + e.codeFrame;
  }

  if (
    // `instanceof` might come from the wrong context
    e.name === 'SyntaxError' &&
    (e.message.includes('Unexpected token') ||
      e.message.includes('Cannot use import')) &&
    !e.message.includes(' expected')
  ) {
    throw enhanceUnexpectedTokenMessage(e);
  }

  return e;
}

function enhanceUnexpectedTokenMessage(e) {
  e.stack =
    `${_chalk().default.bold.red('Jest encountered an unexpected token')}

This usually means that you are trying to import a file which Jest cannot parse, e.g. it's not plain JavaScript.

By default, if Jest sees a Babel config, it will use that to transform your files, ignoring "node_modules".

Here's what you can do:
${DOT}If you are trying to use ECMAScript Modules, see ${_chalk().default.underline(
      'https://jestjs.io/docs/en/ecmascript-modules'
    )} for how to enable it.
${DOT}To have some of your "node_modules" files transformed, you can specify a custom ${_chalk().default.bold(
      '"transformIgnorePatterns"'
    )} in your config.
${DOT}If you need a custom transformation specify a ${_chalk().default.bold(
      '"transform"'
    )} option in your config.
${DOT}If you simply want to mock your non-JS modules (e.g. binary assets) you can stub them out with the ${_chalk().default.bold(
      '"moduleNameMapper"'
    )} config option.

You'll find more details and examples of these config options in the docs:
${_chalk().default.cyan('https://jestjs.io/docs/en/configuration.html')}

${_chalk().default.bold.red('Details:')}

` + e.stack;
  return e;
}
