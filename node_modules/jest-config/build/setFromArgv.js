'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = setFromArgv;

var _utils = require('./utils');

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
const specialArgs = ['_', '$0', 'h', 'help', 'config'];

function setFromArgv(options, argv) {
  const argvToOptions = Object.keys(argv)
    .filter(key => argv[key] !== undefined && specialArgs.indexOf(key) === -1)
    .reduce((options, key) => {
      switch (key) {
        case 'coverage':
          options.collectCoverage = argv[key];
          break;

        case 'json':
          options.useStderr = argv[key];
          break;

        case 'watchAll':
          options.watch = false;
          options.watchAll = argv[key];
          break;

        case 'env':
          options.testEnvironment = argv[key];
          break;

        case 'config':
          break;

        case 'coverageThreshold':
        case 'globals':
        case 'moduleNameMapper':
        case 'transform':
        case 'haste':
          const str = argv[key];

          if ((0, _utils.isJSONString)(str)) {
            options[key] = JSON.parse(str);
          }

          break;

        default:
          options[key] = argv[key];
      }

      return options;
    }, {});
  return {
    ...options,
    ...((0, _utils.isJSONString)(argv.config) ? JSON.parse(argv.config) : null),
    ...argvToOptions
  };
}
