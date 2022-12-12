/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

/**
 * This replicates lodash's once functionality for our purposes.
 */
module.exports = function(func) {
  let called = false;
  let result;
  return function(...args) {
    if (called) {
      return result;
    }
    called = true;
    return result = func.apply(this, args);
  };
};
