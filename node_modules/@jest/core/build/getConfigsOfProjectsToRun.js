'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = getConfigsOfProjectsToRun;

var _getProjectDisplayName = _interopRequireDefault(
  require('./getProjectDisplayName')
);

function _interopRequireDefault(obj) {
  return obj && obj.__esModule ? obj : {default: obj};
}

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
function getConfigsOfProjectsToRun(namesOfProjectsToRun, projectConfigs) {
  const setOfProjectsToRun = new Set(namesOfProjectsToRun);
  return projectConfigs.filter(config => {
    const name = (0, _getProjectDisplayName.default)(config);
    return name && setOfProjectsToRun.has(name);
  });
}
