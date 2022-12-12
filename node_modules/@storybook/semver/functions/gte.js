"use strict";

var compare = require('./compare');

var gte = function gte(a, b, loose) {
  return compare(a, b, loose) >= 0;
};

module.exports = gte;