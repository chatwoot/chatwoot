"use strict";

var compare = require('./compare');

var neq = function neq(a, b, loose) {
  return compare(a, b, loose) !== 0;
};

module.exports = neq;