"use strict";

var compare = require('./compare');

var lte = function lte(a, b, loose) {
  return compare(a, b, loose) <= 0;
};

module.exports = lte;