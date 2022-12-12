"use strict";

var compare = require('./compare');

var eq = function eq(a, b, loose) {
  return compare(a, b, loose) === 0;
};

module.exports = eq;