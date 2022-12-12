
/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

'use strict';

module.exports = function getParser(parserName, options) {
  switch (parserName) {
    case 'babylon':
      return require('../parser/babylon')(options);
    case 'flow':
      return require('../parser/flow')(options);
    case 'ts':
      return require('../parser/ts')(options);
    case 'tsx':
      return require('../parser/tsx')(options);
    case 'babel':
    default:
      return require('../parser/babel5Compat')(options);
  }
};
