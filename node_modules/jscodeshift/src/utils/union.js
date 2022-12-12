/**
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */

module.exports = function(arrays) {
  const result = new Set(arrays[0]);

  let i,j, array;
  for (i = 1; i < arrays.length; i++) {
    array = arrays[i];
    for (j = 0; j < array.length; j++) {
      result.add(array[j]);
    }
  }

  return Array.from(result);
};
