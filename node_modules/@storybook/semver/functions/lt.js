"use strict";

var compare = require('./compare');

var lt = function lt(a, b, loose) {
  return compare(a, b, loose) < 0;
};

module.exports = lt;