'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = getSelectProjectsMessage;

function _chalk() {
  const data = _interopRequireDefault(require('chalk'));

  _chalk = function () {
    return data;
  };

  return data;
}

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
function getSelectProjectsMessage(projectConfigs) {
  if (projectConfigs.length === 0) {
    return getNoSelectionWarning();
  }

  return getProjectsRunningMessage(projectConfigs);
}

function getNoSelectionWarning() {
  return _chalk().default.yellow(
    'You provided values for --selectProjects but no projects were found matching the selection.\n'
  );
}

function getProjectsRunningMessage(projectConfigs) {
  if (projectConfigs.length === 1) {
    const name = (0, _getProjectDisplayName.default)(projectConfigs[0]);
    return `Running one project: ${_chalk().default.bold(name)}\n`;
  }

  const projectsList = projectConfigs
    .map(getProjectNameListElement)
    .sort()
    .join('\n');
  return `Running ${projectConfigs.length} projects:\n${projectsList}\n`;
}

function getProjectNameListElement(projectConfig) {
  const name = (0, _getProjectDisplayName.default)(projectConfig);
  const elementContent = name
    ? _chalk().default.bold(name)
    : '<unnamed project>';
  return `- ${elementContent}`;
}
