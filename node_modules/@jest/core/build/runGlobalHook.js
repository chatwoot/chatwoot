'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = void 0;

function _pEachSeries() {
  const data = _interopRequireDefault(require('p-each-series'));

  _pEachSeries = function () {
    return data;
  };

  return data;
}

function _transform() {
  const data = require('@jest/transform');

  _transform = function () {
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

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
var _default = async ({allTests, globalConfig, moduleName}) => {
  const globalModulePaths = new Set(
    allTests.map(test => test.context.config[moduleName])
  );

  if (globalConfig[moduleName]) {
    globalModulePaths.add(globalConfig[moduleName]);
  }

  if (globalModulePaths.size > 0) {
    await (0, _pEachSeries().default)(
      Array.from(globalModulePaths),
      async modulePath => {
        if (!modulePath) {
          return;
        }

        const correctConfig = allTests.find(
          t => t.context.config[moduleName] === modulePath
        );
        const projectConfig = correctConfig
          ? correctConfig.context.config // Fallback to first config
          : allTests[0].context.config;
        const transformer = new (_transform().ScriptTransformer)(projectConfig);
        await transformer.requireAndTranspileModule(modulePath, async m => {
          const globalModule = (0, _jestUtil().interopRequireDefault)(m)
            .default;

          if (typeof globalModule !== 'function') {
            throw new TypeError(
              `${moduleName} file must export a function at ${modulePath}`
            );
          }

          await globalModule(globalConfig);
        });
      }
    );
  }

  return Promise.resolve();
};

exports.default = _default;
