/*!
 * has-glob <https://github.com/jonschlinkert/has-glob>
 *
 * Copyright (c) 2015, Jon Schlinkert.
 * Licensed under the MIT License.
 */

'use strict';

var isGlob = require('is-glob');

module.exports = function hasGlob(val) {
  if (val == null) return false;
  if (typeof val === 'string') {
    return isGlob(val);
  }
  if (Array.isArray(val)) {
    var len = val.length;
    while (len--) {
      if (isGlob(val[len])) {
        return true;
      }
    }
  }
  return false;
};
