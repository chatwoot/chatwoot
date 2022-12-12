"use strict";

var compare = require('./compare');

var rcompare = function rcompare(a, b, loose) {
  return compare(b, a, loose);
};

module.exports = rcompare;