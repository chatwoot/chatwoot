"use strict";

var compare = require('./compare');

var gt = function gt(a, b, loose) {
  return compare(a, b, loose) > 0;
};

module.exports = gt;