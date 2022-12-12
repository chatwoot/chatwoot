'use strict';

Object.defineProperty(exports, '__esModule', {
  value: true
});
exports.default = getProjectDisplayName;

/**
 * Copyright (c) Facebook, Inc. and its affiliates. All Rights Reserved.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
function getProjectDisplayName(projectConfig) {
  const {displayName} = projectConfig;

  if (!displayName) {
    return undefined;
  }

  return displayName.name;
}
