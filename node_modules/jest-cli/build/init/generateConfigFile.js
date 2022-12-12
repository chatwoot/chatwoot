'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _jestConfig() {
  const data = require('jest-config');

  _jestConfig = function () {
    return data;
  };

  return data;
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
const stringifyOption = (option, map, linePrefix = '') => {
  const optionDescription = `  // ${_jestConfig().descriptions[option]}`;
  const stringifiedObject = `${option}: ${JSON.stringify(
    map[option],
    null,
    2
  )}`;
  return (
    optionDescription +
    '\n' +
    stringifiedObject
      .split('\n')
      .map(line => '  ' + linePrefix + line)
      .join('\n') +
    ',\n'
  );
};

const generateConfigFile = (results, generateEsm = false) => {
  const {
    useTypescript,
    coverage,
    coverageProvider,
    clearMocks,
    environment
  } = results;
  const overrides = {};

  if (coverage) {
    Object.assign(overrides, {
      coverageDirectory: 'coverage'
    });
  }

  if (coverageProvider === 'v8') {
    Object.assign(overrides, {
      coverageProvider: 'v8'
    });
  }

  if (environment === 'node') {
    Object.assign(overrides, {
      testEnvironment: 'node'
    });
  }

  if (clearMocks) {
    Object.assign(overrides, {
      clearMocks: true
    });
  }

  const overrideKeys = Object.keys(overrides);
  const properties = [];

  for (const option in _jestConfig().descriptions) {
    const opt = option;

    if (overrideKeys.includes(opt)) {
      properties.push(stringifyOption(opt, overrides));
    } else {
      properties.push(stringifyOption(opt, _jestConfig().defaults, '// '));
    }
  }

  const configHeaderMessage = `/*
 * For a detailed explanation regarding each configuration property${
   useTypescript ? ' and type check' : ''
 }, visit:
 * https://jestjs.io/docs/en/configuration.html
 */

`;
  return (
    configHeaderMessage +
    (useTypescript || generateEsm
      ? 'export default {\n'
      : 'module.exports = {\n') +
    properties.join('\n') +
    '};\n'
  );
};

var _default = generateConfigFile;
exports.default = _default;
