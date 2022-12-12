/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

module.exports = function(arrays) {
  const result = new Set(arrays[0]);
  let resultSize = result.length;

  let i, value, valuesToCheck;
  for (i = 1; i < arrays.length; i++) {
    valuesToCheck = new Set(arrays[i]);
    for (value of result) {
      if (!valuesToCheck.has(value)) {
        result.delete(value);
        resultSize -= 1;
      }
      if (resultSize === 0) {
        return [];
      }
    }
  }

  return Array.from(result);
};
